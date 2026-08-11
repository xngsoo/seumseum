import Foundation
import Domain

final class StubExpenseRepository: ExpenseRepository, @unchecked Sendable {
    private let expenses: [Expense]
    private let error: DomainError?

    init(expenses: [Expense], error: DomainError? = nil) {
        self.expenses = expenses
        self.error = error
    }

    func expenses(on day: Date) async throws -> [Expense] {
        if let error { throw error }
        return expenses.sorted { $0.sortOrder < $1.sortOrder }
    }

    func expenses(in range: Range<Date>) async throws -> [Expense] {
        if let error { throw error }
        return expenses
    }

    func insert(_ expense: Expense, at index: Int) async throws {}
    func update(_ expense: Expense) async throws {}
    func delete(id: UUID) async throws -> Int { 0 }
    func reorder(_ orderedIDs: [UUID], on day: Date) async throws {}
}

final class StubCategoryRepository: CategoryRepository, @unchecked Sendable {
    private let categories: [ExpenseCategory]

    init(categories: [ExpenseCategory]) { self.categories = categories }

    func categories() async throws -> [ExpenseCategory] { categories }
    func category(id: UUID) async throws -> ExpenseCategory? { categories.first { $0.id == id } }
    func insert(_ category: ExpenseCategory, at index: Int) async throws {}
    func update(_ category: ExpenseCategory) async throws {}
    func expenseCount(using id: UUID) async throws -> Int { 0 }
    func delete(id: UUID) async throws {}
    func reorder(_ orderedIDs: [UUID]) async throws {}
}
