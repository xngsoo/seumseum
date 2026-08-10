import Foundation
import Observation
import Domain

@MainActor
@Observable
public final class DailyViewModel {
    public private(set) var expenses: [Expense] = []
    public private(set) var categories: [UUID: ExpenseCategory] = [:]
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?

    private let expenseRepository: any ExpenseRepository
    private let categoryRepository: any CategoryRepository

    public init(
        expenseRepository: any ExpenseRepository,
        categoryRepository: any CategoryRepository
    ) {
        self.expenseRepository = expenseRepository
        self.categoryRepository = categoryRepository
    }

    public var total: Decimal {
        expenses.reduce(Decimal.zero) { $0 + $1.amount }
    }

    public var isEmpty: Bool { !isLoading && expenses.isEmpty }

    public func category(for expense: Expense) -> ExpenseCategory? {
        categories[expense.categoryID]
    }

    public func load(day: Date) async {
        isLoading = true
        errorMessage = nil
        do {
            async let loadedExpenses = expenseRepository.expenses(on: day)
            async let loadedCategories = categoryRepository.categories()
            let (fetched, allCategories) = try await (loadedExpenses, loadedCategories)
            expenses = fetched
            categories = Dictionary(
                allCategories.map { ($0.id, $0) },
                uniquingKeysWith: { first, _ in first }
            )
        } catch {
            errorMessage = error.localizedDescription
            expenses = []
        }
        isLoading = false
    }
}
