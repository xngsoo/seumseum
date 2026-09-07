import Foundation
import Testing
import Shared
import Domain
@testable import Editor

@MainActor
@Suite("수정 화면의 삭제")
struct ExpenseEditorDeleteTests {

    private let day = CalendarDay.today()

    private func makeViewModel(
        _ route: EditorRoute, deletedIndex: Int = 0
    ) -> (ExpenseEditorViewModel, DeletingRepository) {
        let repository = DeletingRepository(deletedIndex: deletedIndex)
        let viewModel = ExpenseEditorViewModel(
            route: route,
            expenseRepository: repository,
            categoryRepository: EmptyCategoryRepository(),
            settingsRepository: DefaultSettingsRepository()
        )
        return (viewModel, repository)
    }

    @Test("원본을 지우고 지워진 자리를 돌려준다")
    func deleteReturnsIndex() async {
        let original = Expense(amount: 5_000, memo: "커피", categoryID: UUID(), date: day, sortOrder: 2)
        let (viewModel, repository) = makeViewModel(.edit(original), deletedIndex: 2)

        let index = await viewModel.delete()

        #expect(index == 2)
        #expect(repository.deletedID == original.id)
    }

    @Test("추가 화면에서는 지울 것이 없다")
    func createCannotDelete() async {
        let (viewModel, repository) = makeViewModel(.create(day: day))

        #expect(await viewModel.delete() == nil)
        #expect(repository.deletedID == nil)
    }

    @Test("삭제가 실패하면 자리를 돌려주지 않고 이유를 남긴다")
    func deleteFailureKeepsMessage() async {
        let original = Expense(amount: 5_000, memo: "커피", categoryID: UUID(), date: day)
        let (viewModel, repository) = makeViewModel(.edit(original))
        repository.fails = true

        #expect(await viewModel.delete() == nil)
        #expect(viewModel.errorMessage != nil)
    }
}

private final class DeletingRepository: ExpenseRepository, @unchecked Sendable {
    private(set) var deletedID: UUID?
    var fails = false
    private let deletedIndex: Int

    init(deletedIndex: Int) { self.deletedIndex = deletedIndex }

    func expenses(on day: Date) async throws -> [Expense] { [] }
    func expenses(in range: Range<Date>) async throws -> [Expense] { [] }
    func insert(_ expense: Expense, at index: Int) async throws {}
    func update(_ expense: Expense) async throws {}
    func delete(id: UUID) async throws -> Int {
        if fails { throw DomainError.expenseNotFound(id) }
        deletedID = id
        return deletedIndex
    }
    func reorder(_ orderedIDs: [UUID], on day: Date) async throws {}
}

private final class EmptyCategoryRepository: CategoryRepository, @unchecked Sendable {
    func categories() async throws -> [ExpenseCategory] { [] }
    func category(id: UUID) async throws -> ExpenseCategory? { nil }
    func insert(_ category: ExpenseCategory, at index: Int) async throws {}
    func update(_ category: ExpenseCategory) async throws {}
    func expenseCount(using id: UUID) async throws -> Int { 0 }
    func delete(id: UUID) async throws {}
    func reorder(_ orderedIDs: [UUID]) async throws {}
}

private final class DefaultSettingsRepository: SettingsRepository, @unchecked Sendable {
    func settings() async throws -> AppSettings { .default }
    func update(_ settings: AppSettings) async throws {}
}
