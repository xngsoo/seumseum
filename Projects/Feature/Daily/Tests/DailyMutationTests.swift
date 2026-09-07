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

    @Test("조회를 마쳐야 화면의 날짜가 바뀐다")
    func loadedDayFollowsFetchedData() async {
        let (viewModel, _) = await makeViewModel(["A"])
        #expect(viewModel.loadedDay == day)

        let tomorrow = CalendarDay.adding(days: 1, to: day)
        await viewModel.load(day: tomorrow)

        #expect(viewModel.loadedDay == tomorrow)
    }

    @Test("수정 화면이 지운 기록을 넘기면 취소 정보가 남는다")
    func registerUndo() async {
        let (viewModel, repository) = await makeViewModel(["A", "B", "C"])
        let middle = viewModel.expenses[1]

        // 삭제는 수정 화면이 이미 마친 상태다.
        _ = try? await repository.delete(id: middle.id)
        viewModel.registerUndo(expense: middle, at: 1)

        #expect(viewModel.pendingUndo?.index == 1)
        #expect(viewModel.pendingUndo?.expense.id == middle.id)
    }

    @Test("취소는 원래 자리로 되돌린다")
    func undo() async {
        let (viewModel, repository) = await makeViewModel(["A", "B", "C"])
        let middle = viewModel.expenses[1]

        _ = try? await repository.delete(id: middle.id)
        viewModel.registerUndo(expense: middle, at: 1)
        await viewModel.undoDelete()

        #expect(viewModel.expenses.map(\.memo) == ["A", "B", "C"])
        #expect(viewModel.pendingUndo == nil)
        let stored = try? await repository.expenses(on: day)
        #expect(stored?.map(\.sortOrder) == [0, 1, 2])
    }

    @Test("스낵바를 닫으면 취소 정보가 사라진다")
    func dismissUndo() async {
        let (viewModel, _) = await makeViewModel(["A"])
        viewModel.registerUndo(expense: viewModel.expenses[0], at: 0)
        #expect(viewModel.pendingUndo != nil)

        viewModel.dismissUndo()
        #expect(viewModel.pendingUndo == nil)
    }
}
