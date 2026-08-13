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

    /// 지난달 같은 기간과의 비교. 조회 전에는 nil.
    private(set) var comparison: MonthComparison?

    /// 화면에 실제로 그려지고 있는 달. 조회가 끝나야 바뀐다.
    /// 달을 넘기는 애니메이션은 이 값을 기준으로 삼아야 이전 달 합계를 든 채로
    /// 새 달력이 들어오지 않는다.
    public private(set) var loadedMonth: Date = CalendarDay.startOfMonth(
        containing: CalendarDay.today()
    )

    private let expenseRepository: any ExpenseRepository

    public init(expenseRepository: any ExpenseRepository) {
        self.expenseRepository = expenseRepository
    }

    public func total(on day: Date) -> Decimal? {
        totalsByDay[day]
    }

    public func load(month day: Date) async {
        let monthStart = CalendarDay.startOfMonth(containing: day)
        let previousStart = CalendarDay.startOfMonth(
            containing: CalendarDay.adding(months: -1, to: monthStart)
        )
        isLoading = true
        errorMessage = nil
        do {
            // 지난달은 같은 기간을 견주기 위해서만 읽는다. 달력에는 그리지 않는다.
            async let current = expenseRepository.expenses(
                in: CalendarDay.monthRange(containing: monthStart)
            )
            async let previous = expenseRepository.expenses(
                in: CalendarDay.monthRange(containing: previousStart)
            )
            let (currentExpenses, previousExpenses) = try await (current, previous)

            let totals = Self.totalsByDay(currentExpenses)
            totalsByDay = totals
            monthTotal = totals.values.reduce(Decimal.zero, +)
            comparison = MonthComparison.make(
                month: monthStart,
                today: CalendarDay.today(),
                currentTotalsByDay: totals,
                previousTotalsByDay: Self.totalsByDay(previousExpenses)
            )
        } catch {
            errorMessage = error.localizedDescription
            totalsByDay = [:]
            monthTotal = .zero
            comparison = nil
        }
        loadedMonth = monthStart
        isLoading = false
    }

    private static func totalsByDay(_ expenses: [Expense]) -> [Date: Decimal] {
        var totals: [Date: Decimal] = [:]
        for expense in expenses {
            totals[expense.date, default: .zero] += expense.amount
        }
        return totals
    }
}
