import Foundation
import Testing
import Shared
import Domain
@testable import Daily

@MainActor
@Suite("DailyViewModel 변경")
struct DailyMutationTests {

    private let day = CalendarDay.today()

    private func makeViewModel(_ memos: [String]) async -> (DailyViewModel, FakeExpenseRepository) {
        let categoryID = UUID()
        let seeded = memos.enumerated().map { index, memo in
            Expense(amount: 1_000, memo: memo, categoryID: categoryID, date: day, sortOrder: index)
        }
        let repository = FakeExpenseRepository([day: seeded])
        let viewModel = DailyViewModel(
            expenseRepository: repository,
            categoryRepository: StubCategoryRepository(categories: [])
        )
        await viewModel.load(day: day)
        return (viewModel, repository)
    }

    @Test("재정렬은 화면과 저장소 순서를 함께 바꾼다")
    func move() async {
        let (viewModel, repository) = await makeViewModel(["A", "B", "C"])

        await viewModel.move(from: IndexSet(integer: 2), to: 0)

        #expect(viewModel.expenses.map(\.memo) == ["C", "A", "B"])
        let stored = try? await repository.expenses(on: day)
        #expect(stored?.map(\.memo) == ["C", "A", "B"])
        #expect(stored?.map(\.sortOrder) == [0, 1, 2])
    }

    @Test("드래그 중에는 화면 순서만 바뀌고 저장은 손을 뗄 때 한 번만 한다")
    func moveLocallyDefersSaving() async {
        let (viewModel, repository) = await makeViewModel(["A", "B", "C"])

        viewModel.moveLocally(from: 2, to: 1)
        viewModel.moveLocally(from: 1, to: 0)

        #expect(viewModel.expenses.map(\.memo) == ["C", "A", "B"])
        var stored = try? await repository.expenses(on: day)
        #expect(stored?.map(\.memo) == ["A", "B", "C"])

        await viewModel.commitReorder()

        stored = try? await repository.expenses(on: day)
        #expect(stored?.map(\.memo) == ["C", "A", "B"])
        #expect(stored?.map(\.sortOrder) == [0, 1, 2])
    }

    @Test("드래그 저장이 실패하면 드래그 시작 전 순서로 되돌린다")
    func commitReorderFailureRollsBack() async {
        let categoryID = UUID()
        let seeded = ["A", "B", "C"].enumerated().map { index, memo in
            Expense(amount: 1_000, memo: memo, categoryID: categoryID, date: day, sortOrder: index)
        }
        let viewModel = DailyViewModel(
            expenseRepository: FailingReorderRepository(seeded),
            categoryRepository: StubCategoryRepository(categories: [])
        )
        await viewModel.load(day: day)

        viewModel.moveLocally(from: 2, to: 1)
        viewModel.moveLocally(from: 1, to: 0)
        await viewModel.commitReorder()

        #expect(viewModel.expenses.map(\.memo) == ["A", "B", "C"])
        #expect(viewModel.errorMessage != nil)
    }

    @Test("삭제하면 목록에서 빠지고 취소 정보가 남는다")
    func delete() async {
        let (viewModel, _) = await makeViewModel(["A", "B", "C"])
        let middle = viewModel.expenses[1]

        await viewModel.delete(middle)

        #expect(viewModel.expenses.map(\.memo) == ["A", "C"])
        #expect(viewModel.pendingUndo?.index == 1)
        #expect(viewModel.pendingUndo?.expense.id == middle.id)
    }

    @Test("취소는 원래 자리로 되돌린다")
    func undo() async {
        let (viewModel, repository) = await makeViewModel(["A", "B", "C"])
        let middle = viewModel.expenses[1]

        await viewModel.delete(middle)
        await viewModel.undoDelete()

        #expect(viewModel.expenses.map(\.memo) == ["A", "B", "C"])
        #expect(viewModel.pendingUndo == nil)
        let stored = try? await repository.expenses(on: day)
        #expect(stored?.map(\.sortOrder) == [0, 1, 2])
    }

    @Test("스낵바를 닫으면 취소 정보가 사라진다")
    func dismissUndo() async {
        let (viewModel, _) = await makeViewModel(["A"])
        await viewModel.delete(viewModel.expenses[0])
        #expect(viewModel.pendingUndo != nil)

        viewModel.dismissUndo()
        #expect(viewModel.pendingUndo == nil)
    }

    @Test("재정렬이 실패하면 이전 순서로 되돌린다")
    func moveFailureRollsBack() async {
        let categoryID = UUID()
        let seeded = ["A", "B"].enumerated().map { index, memo in
            Expense(amount: 1_000, memo: memo, categoryID: categoryID, date: day, sortOrder: index)
        }
        let viewModel = DailyViewModel(
            expenseRepository: FailingReorderRepository(seeded),
            categoryRepository: StubCategoryRepository(categories: [])
        )
        await viewModel.load(day: day)

        await viewModel.move(from: IndexSet(integer: 1), to: 0)

        #expect(viewModel.expenses.map(\.memo) == ["A", "B"])
        #expect(viewModel.errorMessage != nil)
    }
}

private actor FailingReorderRepository: ExpenseRepository {
    private let items: [Expense]
    init(_ items: [Expense]) { self.items = items }

    func expenses(on day: Date) async throws -> [Expense] { items }
    func expenses(in range: Range<Date>) async throws -> [Expense] { items }
    func insert(_ expense: Expense, at index: Int) async throws {}
    func update(_ expense: Expense) async throws {}
    func delete(id: UUID) async throws -> Int { 0 }
    func reorder(_ orderedIDs: [UUID], on day: Date) async throws {
        throw DomainError.storageFailed("재정렬 실패")
    }
}
