import Foundation
import Observation
import Domain
import Shared

@MainActor
@Observable
public final class MonthlyViewModel {

    public private(set) var totalsByDay: [Date: Decimal] = [:]
    public private(set) var monthTotal: Decimal = .zero
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?

    private let expenseRepository: any ExpenseRepository

    public init(expenseRepository: any ExpenseRepository) {
        self.expenseRepository = expenseRepository
    }

    public func total(on day: Date) -> Decimal? {
        totalsByDay[day]
    }

    public func load(month day: Date) async {
        isLoading = true
        errorMessage = nil
        do {
            let range = CalendarDay.monthRange(containing: day)
            let expenses = try await expenseRepository.expenses(in: range)
            var totals: [Date: Decimal] = [:]
            for expense in expenses {
                totals[expense.date, default: .zero] += expense.amount
            }
            totalsByDay = totals
            monthTotal = totals.values.reduce(Decimal.zero, +)
        } catch {
            errorMessage = error.localizedDescription
            totalsByDay = [:]
            monthTotal = .zero
        }
        isLoading = false
    }
}
