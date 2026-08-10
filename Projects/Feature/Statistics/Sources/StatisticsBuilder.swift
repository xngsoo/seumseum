import Foundation
import Domain
import Shared

/// 조회 결과를 화면이 쓰는 형태로 바꾼다. 저장소를 모르는 순수 계산이라 따로 둔다.
enum StatisticsBuilder {

    static func make(
        period: PayPeriod,
        expenses: [Expense],
        previousExpenses: [Expense],
        categories: [UUID: ExpenseCategory]
    ) -> StatisticsSummary {
        let total = expenses.reduce(Decimal.zero) { $0 + $1.amount }
        let previousTotal = previousExpenses.reduce(Decimal.zero) { $0 + $1.amount }

        return StatisticsSummary(
            period: period,
            total: total,
            previousTotal: previousTotal,
            dailyAverage: dailyAverage(total: total, period: period),
            categoryShares: shares(expenses: expenses, total: total, categories: categories),
            weeklyTotals: weeklyTotals(period: period, expenses: expenses)
        )
    }

    private static func dailyAverage(total: Decimal, period: PayPeriod) -> Decimal {
        let days = CalendarDay.dayCount(in: period.range)
        guard days > 0 else { return .zero }
        var result = Decimal()
        var quotient = total / Decimal(days)
        NSDecimalRound(&result, &quotient, 0, .down)
        return result
    }

    private static func shares(
        expenses: [Expense], total: Decimal, categories: [UUID: ExpenseCategory]
    ) -> [CategoryShare] {
        guard total > .zero else { return [] }
        var sums: [UUID: Decimal] = [:]
        for expense in expenses {
            sums[expense.categoryID, default: .zero] += expense.amount
        }
        let totalValue = NSDecimalNumber(decimal: total).doubleValue

        return sums.compactMap { categoryID, amount -> CategoryShare? in
            guard let category = categories[categoryID] else { return nil }
            return CategoryShare(
                category: category,
                amount: amount,
                ratio: NSDecimalNumber(decimal: amount).doubleValue / totalValue
            )
        }
        .sorted { lhs, rhs in
            lhs.amount == rhs.amount
                ? lhs.category.sortOrder < rhs.category.sortOrder
                : lhs.amount > rhs.amount
        }
    }

    private static func weeklyTotals(period: PayPeriod, expenses: [Expense]) -> [WeeklyTotal] {
        var results: [WeeklyTotal] = []
        var start = period.start
        var week = 1
        while start < period.end {
            let end = min(CalendarDay.adding(days: 7, to: start), period.end)
            let amount = expenses
                .filter { $0.date >= start && $0.date < end }
                .reduce(Decimal.zero) { $0 + $1.amount }
            results.append(WeeklyTotal(week: week, range: start ..< end, amount: amount))
            start = end
            week += 1
        }
        return results
    }
}
