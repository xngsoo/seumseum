import Foundation
import Testing
import Shared
import Domain
@testable import Editor

@MainActor
@Suite("ExpenseEditorViewModel")
struct ExpenseEditorViewModelTests {

    private let day = CalendarDay.today()

    private func makeViewModel(_ route: EditorRoute) -> (ExpenseEditorViewModel, RecordingRepository) {
        let repository = RecordingRepository()
        let category = ExpenseCategory(name: "식비", symbolName: "fork.knife", colorToken: .orange)
        let viewModel = ExpenseEditorViewModel(
            route: route,
            expenseRepository: repository,
            categoryRepository: FixedCategoryRepository(categories: [category])
        )
        return (viewModel, repository)
    }

    @Test("금액 입력은 숫자만 남기고 앞자리 0을 없앤다")
    func amountFiltering() {
        let (viewModel, _) = makeViewModel(.create(day: day))
        viewModel.updateAmount("0012a3,4원")
        #expect(viewModel.amountDigits == "1234")
        #expect(viewModel.amount == 1234)
    }

    @Test("입력 필드 표기는 축약하지 않는다")
    func formatting() {
        let (viewModel, _) = makeViewModel(.create(day: day))
        viewModel.updateAmount("1535000")
        #expect(viewModel.formattedAmount == "1,535,000원")
    }

    @Test("금액이 0이거나 카테고리가 없으면 저장할 수 없다")
    func canSave() async {
        let (viewModel, _) = makeViewModel(.create(day: day))
        #expect(!viewModel.canSave)

        await viewModel.load()
        #expect(!viewModel.canSave, "금액이 0이면 아직 저장 불가")

        viewModel.updateAmount("1000")
        #expect(viewModel.canSave)
    }

    @Test("load 는 첫 카테고리를 기본 선택한다")
    func defaultCategory() async {
        let (viewModel, _) = makeViewModel(.create(day: day))
        await viewModel.load()
        #expect(viewModel.categoryID != nil)
    }

    @Test("생성 저장은 0번에 삽입하고 날짜가 바뀌지 않는다")
    func createSaves() async {
        let (viewModel, repository) = makeViewModel(.create(day: day))
        await viewModel.load()
        viewModel.updateAmount("9500")
        viewModel.memo = "점심"

        #expect(await viewModel.save())
        #expect(repository.insertedIndex == 0)
        #expect(repository.inserted?.amount == 9500)
        #expect(repository.inserted?.memo == "점심")
        #expect(repository.inserted?.date == day, "달력일이 그대로 유지되어야 한다")
    }

    @Test("수정 모드는 기존 값을 채우고 id 를 유지한다")
    func editPrefillsAndKeepsIdentity() async {
        let category = UUID()
        let original = Expense(amount: 4_800, memo: "커피", categoryID: category, date: day, sortOrder: 2)
        let (viewModel, repository) = makeViewModel(.edit(original))

        #expect(viewModel.amountDigits == "4800")
        #expect(viewModel.memo == "커피")
        #expect(viewModel.day == day)

        await viewModel.load()
        viewModel.updateAmount("5000")
        #expect(await viewModel.save())

        #expect(repository.updated?.id == original.id)
        #expect(repository.updated?.amount == 5000)
        #expect(repository.updated?.createdAt == original.createdAt)
    }

    @Test("수정에서 날짜를 옮겨도 달력일이 밀리지 않는다")
    func editMovesDay() async {
        let original = Expense(amount: 1_000, categoryID: UUID(), date: day)
        let (viewModel, repository) = makeViewModel(.edit(original))
        await viewModel.load()

        let tomorrow = CalendarDay.adding(days: 1, to: day)
        viewModel.day = tomorrow
        #expect(await viewModel.save())
        #expect(repository.updated?.date == tomorrow)
    }
}

private final class RecordingRepository: ExpenseRepository, @unchecked Sendable {
    private(set) var inserted: Expense?
    private(set) var insertedIndex: Int?
    private(set) var updated: Expense?

    func expenses(on day: Date) async throws -> [Expense] { [] }
    func expenses(in range: Range<Date>) async throws -> [Expense] { [] }
    func insert(_ expense: Expense, at index: Int) async throws {
        inserted = expense
        insertedIndex = index
    }
    func update(_ expense: Expense) async throws { updated = expense }
    func delete(id: UUID) async throws -> Int { 0 }
    func reorder(_ orderedIDs: [UUID], on day: Date) async throws {}
}

private final class FixedCategoryRepository: CategoryRepository, @unchecked Sendable {
    private let categories: [ExpenseCategory]
    init(categories: [ExpenseCategory]) { self.categories = categories }

    func categories() async throws -> [ExpenseCategory] { categories }
    func category(id: UUID) async throws -> ExpenseCategory? { categories.first { $0.id == id } }
    func insert(_ category: ExpenseCategory, at index: Int) async throws {}
    func update(_ category: ExpenseCategory) async throws {}
    func delete(id: UUID) async throws {}
    func reorder(_ orderedIDs: [UUID]) async throws {}
}

@MainActor
@Suite("금액 입력 표기")
struct AmountFieldTests {

    private func makeViewModel() -> ExpenseEditorViewModel {
        ExpenseEditorViewModel(
            route: .create(day: CalendarDay.today()),
            expenseRepository: NoopExpenseRepository(),
            categoryRepository: NoopCategoryRepository()
        )
    }

    @Test("편집 대상 문자열에는 단위가 들어가지 않는다")
    func groupedHasNoUnit() {
        let viewModel = makeViewModel()
        viewModel.updateAmount("1535000")
        #expect(viewModel.groupedAmount == "1,535,000")
        #expect(!viewModel.groupedAmount.contains("원"))
    }

    @Test("금액을 모두 지우면 빈 문자열이 된다")
    func clearedIsEmpty() {
        let viewModel = makeViewModel()
        viewModel.updateAmount("1234")
        viewModel.updateAmount("")
        #expect(viewModel.groupedAmount.isEmpty)
        #expect(viewModel.amount == .zero)
    }

    @Test("서식이 적용된 문자열을 되돌려 받아도 숫자만 남는다")
    func roundTripThroughFormatting() {
        let viewModel = makeViewModel()
        viewModel.updateAmount("1535000")
        // TextField 가 서식 문자열을 그대로 돌려주는 상황
        viewModel.updateAmount(viewModel.groupedAmount)
        #expect(viewModel.amountDigits == "1535000")

        // 뒤에서 한 글자 지운 상황
        viewModel.updateAmount(String(viewModel.groupedAmount.dropLast()))
        #expect(viewModel.amountDigits == "153500")
    }
}

private final class NoopExpenseRepository: ExpenseRepository, @unchecked Sendable {
    func expenses(on day: Date) async throws -> [Expense] { [] }
    func expenses(in range: Range<Date>) async throws -> [Expense] { [] }
    func insert(_ expense: Expense, at index: Int) async throws {}
    func update(_ expense: Expense) async throws {}
    func delete(id: UUID) async throws -> Int { 0 }
    func reorder(_ orderedIDs: [UUID], on day: Date) async throws {}
}

private final class NoopCategoryRepository: CategoryRepository, @unchecked Sendable {
    func categories() async throws -> [ExpenseCategory] { [] }
    func category(id: UUID) async throws -> ExpenseCategory? { nil }
    func insert(_ category: ExpenseCategory, at index: Int) async throws {}
    func update(_ category: ExpenseCategory) async throws {}
    func delete(id: UUID) async throws {}
    func reorder(_ orderedIDs: [UUID]) async throws {}
}
