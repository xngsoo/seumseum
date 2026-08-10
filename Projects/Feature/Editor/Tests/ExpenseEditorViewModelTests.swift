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
            categoryRepository: FixedCategoryRepository(categories: [category]),
            settingsRepository: FixedSettingsRepository()
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
        #expect(repository.inserted.first?.amount == 9500)
        #expect(repository.inserted.first?.memo == "점심")
        #expect(repository.inserted.first?.date == day, "달력일이 그대로 유지되어야 한다")
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
    private(set) var inserted: [Expense] = []
    private(set) var insertedIndex: Int?
    private(set) var updated: Expense?

    func expenses(on day: Date) async throws -> [Expense] { [] }
    func expenses(in range: Range<Date>) async throws -> [Expense] { [] }
    func insert(_ expense: Expense, at index: Int) async throws {
        inserted.append(expense)
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
            categoryRepository: NoopCategoryRepository(),
            settingsRepository: FixedSettingsRepository()
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

private actor FixedSettingsRepository: SettingsRepository {
    private var stored: AppSettings

    init(splitItem: SplitItem? = nil) {
        stored = AppSettings(splitItem: splitItem)
    }

    func settings() async throws -> AppSettings { stored }
    func update(_ settings: AppSettings) async throws { stored = settings }
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

@MainActor
@Suite("정액 품목 분리")
struct SplitItemTests {

    private let day = CalendarDay.today()
    private let tobaccoCategory = ExpenseCategory(name: "담배", symbolName: "smoke", colorToken: .gray)
    private let storeCategory = ExpenseCategory(name: "편의점", symbolName: "cart", colorToken: .green, sortOrder: 1)

    private func makeViewModel(unitAmount: Decimal = 4_500) -> (ExpenseEditorViewModel, RecordingRepository) {
        let repository = RecordingRepository()
        let item = SplitItem(
            name: "담배", unitAmount: unitAmount,
            categoryID: tobaccoCategory.id, unitLabel: "갑"
        )
        let viewModel = ExpenseEditorViewModel(
            route: .create(day: day),
            expenseRepository: repository,
            categoryRepository: FixedCategoryRepository(categories: [storeCategory, tobaccoCategory]),
            settingsRepository: FixedSettingsRepository(splitItem: item)
        )
        return (viewModel, repository)
    }

    @Test("수량이 0이면 한 건으로 저장된다")
    func noSplit() async {
        let (viewModel, repository) = makeViewModel()
        await viewModel.load()
        viewModel.updateAmount("12000")

        #expect(await viewModel.save())
        #expect(repository.inserted.count == 1)
        #expect(repository.inserted.first?.amount == 12_000)
    }

    @Test("수량을 넣으면 두 건으로 나뉜다")
    func splitsIntoTwo() async {
        let (viewModel, repository) = makeViewModel()
        await viewModel.load()
        viewModel.updateAmount("12000")
        viewModel.memo = "간식"
        viewModel.splitQuantity = 2

        #expect(await viewModel.save())
        #expect(repository.inserted.count == 2)

        let tobacco = repository.inserted.first { $0.categoryID == tobaccoCategory.id }
        let store = repository.inserted.first { $0.categoryID == storeCategory.id }
        #expect(tobacco?.amount == 9_000)
        #expect(tobacco?.memo == "담배 2갑")
        #expect(store?.amount == 3_000)
        #expect(store?.memo == "간식")
    }

    @Test("합계는 원래 금액과 같다")
    func totalPreserved() async {
        let (viewModel, repository) = makeViewModel()
        await viewModel.load()
        viewModel.updateAmount("12000")
        viewModel.splitQuantity = 2
        _ = await viewModel.save()

        let total = repository.inserted.reduce(Decimal.zero) { $0 + $1.amount }
        #expect(total == 12_000)
    }

    @Test("분리 금액이 총액과 같으면 한 건만 남는다")
    func exactAmount() async {
        let (viewModel, repository) = makeViewModel()
        await viewModel.load()
        viewModel.updateAmount("9000")
        viewModel.splitQuantity = 2

        #expect(await viewModel.save())
        #expect(repository.inserted.count == 1)
        #expect(repository.inserted.first?.categoryID == tobaccoCategory.id)
    }

    @Test("분리 금액이 총액을 넘으면 저장할 수 없다")
    func overflow() async {
        let (viewModel, _) = makeViewModel()
        await viewModel.load()
        viewModel.updateAmount("5000")
        viewModel.splitQuantity = 2

        #expect(!viewModel.isSplitAmountValid)
        #expect(!viewModel.canSave)
    }

    @Test("미리보기에 나뉜 결과가 보인다")
    func preview() async {
        let (viewModel, _) = makeViewModel()
        await viewModel.load()
        viewModel.categoryID = storeCategory.id
        viewModel.updateAmount("12000")
        viewModel.splitQuantity = 2

        #expect(viewModel.splitPreview == "담배 2갑 9,000원 · 편의점 3,000원")
    }

    @Test("수정 화면에서는 분리 입력을 보여주지 않는다")
    func hiddenWhenEditing() async {
        let existing = Expense(amount: 1_000, categoryID: storeCategory.id, date: day)
        let viewModel = ExpenseEditorViewModel(
            route: .edit(existing),
            expenseRepository: RecordingRepository(),
            categoryRepository: FixedCategoryRepository(categories: [storeCategory, tobaccoCategory]),
            settingsRepository: FixedSettingsRepository(
                splitItem: SplitItem(name: "담배", unitAmount: 4_500, categoryID: tobaccoCategory.id)
            )
        )
        await viewModel.load()

        #expect(!viewModel.showsSplitField)
    }

    @Test("대상 카테고리가 지워졌으면 기능을 감춘다")
    func missingCategory() async {
        let viewModel = ExpenseEditorViewModel(
            route: .create(day: day),
            expenseRepository: RecordingRepository(),
            categoryRepository: FixedCategoryRepository(categories: [storeCategory]),
            settingsRepository: FixedSettingsRepository(
                splitItem: SplitItem(name: "담배", unitAmount: 4_500, categoryID: UUID())
            )
        )
        await viewModel.load()

        #expect(viewModel.splitItem == nil)
        #expect(!viewModel.showsSplitField)
    }
}
