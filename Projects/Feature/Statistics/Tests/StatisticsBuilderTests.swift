import Foundation
import Testing
import Shared
import Domain
@testable import Statistics

@Suite("StatisticsBuilder")
struct StatisticsBuilderTests {

    private func day(_ y: Int, _ m: Int, _ d: Int) throws -> Date {
        try #require(CalendarDay.date(year: y, month: m, day: d))
    }

    private func makeCategories() -> ([UUID: ExpenseCategory], food: UUID, cafe: UUID) {
        let food = ExpenseCategory(name: "식비", symbolName: "fork.knife", colorToken: .orange, sortOrder: 0)
        let cafe = ExpenseCategory(name: "카페", symbolName: "cup.and.saucer", colorToken: .brown, sortOrder: 1)
        return ([food.id: food, cafe.id: cafe], food.id, cafe.id)
    }

    @Test("총액·일평균·기간 표기")
    func totals() throws {
        let (categories, food, _) = makeCategories()
        let period = PayPeriod(start: try day(2026, 8, 1), end: try day(2026, 9, 1))  // 31일
        let expenses = [
            Expense(amount: 30_000, categoryID: food, date: try day(2026, 8, 2)),
            Expense(amount: 32_000, categoryID: food, date: try day(2026, 8, 3)),
        ]

        let summary = StatisticsBuilder.make(
            period: period, expenses: expenses, previousExpenses: [], categories: categories
        )

        #expect(summary.total == 62_000)
        #expect(summary.dailyAverage == 2_000)          // 62000 / 31
        #expect(summary.periodText == "8/1 – 8/31")
        #expect(!summary.isEmpty)
    }

    @Test("카테고리 몫은 금액 내림차순이고 비율의 합은 1")
    func shares() throws {
        let (categories, food, cafe) = makeCategories()
        let period = PayPeriod(start: try day(2026, 8, 1), end: try day(2026, 9, 1))
        let expenses = [
            Expense(amount: 20_000, categoryID: cafe, date: try day(2026, 8, 2)),
            Expense(amount: 60_000, categoryID: food, date: try day(2026, 8, 3)),
            Expense(amount: 20_000, categoryID: food, date: try day(2026, 8, 4)),
        ]

        let summary = StatisticsBuilder.make(
            period: period, expenses: expenses, previousExpenses: [], categories: categories
        )

        #expect(summary.categoryShares.map(\.category.name) == ["식비", "카페"])
        #expect(summary.categoryShares.first?.amount == 80_000)
        #expect(summary.topCategory?.category.name == "식비")
        let ratioSum = summary.categoryShares.reduce(0.0) { $0 + $1.ratio }
        #expect(abs(ratioSum - 1.0) < 0.0001)
    }

    @Test("지워진 카테고리를 참조하는 지출은 몫에서 빠진다")
    func missingCategory() throws {
        let (categories, food, _) = makeCategories()
        let period = PayPeriod(start: try day(2026, 8, 1), end: try day(2026, 9, 1))
        let expenses = [
            Expense(amount: 10_000, categoryID: food, date: try day(2026, 8, 2)),
            Expense(amount: 5_000, categoryID: UUID(), date: try day(2026, 8, 3)),
        ]

        let summary = StatisticsBuilder.make(
            period: period, expenses: expenses, previousExpenses: [], categories: categories
        )

        #expect(summary.total == 15_000, "총액에는 포함된다")
        #expect(summary.categoryShares.count == 1, "몫에는 빠진다")
    }

    @Test("주차는 7일씩 끊고 마지막 주는 주기 끝에서 잘린다")
    func weeks() throws {
        let (categories, food, _) = makeCategories()
        let period = PayPeriod(start: try day(2026, 8, 1), end: try day(2026, 9, 1))  // 31일
        let expenses = [
            Expense(amount: 1_000, categoryID: food, date: try day(2026, 8, 1)),   // 1주
            Expense(amount: 2_000, categoryID: food, date: try day(2026, 8, 8)),   // 2주
            Expense(amount: 3_000, categoryID: food, date: try day(2026, 8, 31)),  // 5주
        ]

        let summary = StatisticsBuilder.make(
            period: period, expenses: expenses, previousExpenses: [], categories: categories
        )

        #expect(summary.weeklyTotals.count == 5)
        #expect(summary.weeklyTotals[0].amount == 1_000)
        #expect(summary.weeklyTotals[1].amount == 2_000)
        #expect(summary.weeklyTotals[4].amount == 3_000)
        #expect(summary.weeklyTotals.last?.range.upperBound == period.end)
        #expect(summary.weeklyTotals.map(\.amount).reduce(Decimal.zero, +) == summary.total)
    }

    @Test("직전 주기 대비 증감")
    func comparison() throws {
        let (categories, food, _) = makeCategories()
        let period = PayPeriod(start: try day(2026, 8, 1), end: try day(2026, 9, 1))
        let summary = StatisticsBuilder.make(
            period: period,
            expenses: [Expense(amount: 120_000, categoryID: food, date: try day(2026, 8, 2))],
            previousExpenses: [Expense(amount: 100_000, categoryID: food, date: try day(2026, 7, 2))],
            categories: categories
        )

        #expect(summary.change == 20_000)
        #expect(summary.hasComparison)
        #expect(abs((summary.changeRatio ?? 0) - 0.2) < 0.0001)
    }

    @Test("직전 주기에 기록이 없으면 비교하지 않는다")
    func noComparison() throws {
        let (categories, food, _) = makeCategories()
        let period = PayPeriod(start: try day(2026, 8, 1), end: try day(2026, 9, 1))
        let summary = StatisticsBuilder.make(
            period: period,
            expenses: [Expense(amount: 1_000, categoryID: food, date: try day(2026, 8, 2))],
            previousExpenses: [],
            categories: categories
        )

        #expect(!summary.hasComparison)
        #expect(summary.changeRatio == nil)
    }

    @Test("기록이 없으면 빈 요약이다")
    func empty() throws {
        let (categories, _, _) = makeCategories()
        let period = PayPeriod(start: try day(2026, 8, 1), end: try day(2026, 9, 1))
        let summary = StatisticsBuilder.make(
            period: period, expenses: [], previousExpenses: [], categories: categories
        )

        #expect(summary.isEmpty)
        #expect(summary.categoryShares.isEmpty)
        #expect(summary.dailyAverage == .zero)
        #expect(summary.weeklyTotals.count == 5, "기록이 없어도 주차 축은 그린다")
    }
}
