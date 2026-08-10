import Foundation
import Observation
import Domain
import Shared

@MainActor
@Observable
public final class StatisticsViewModel {

    public private(set) var summary: StatisticsSummary = .empty
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?

    /// 현재 보고 있는 주기 안의 아무 날짜. 주기 이동의 기준점이다.
    private var anchor: Date
    private var setting: PayPeriodSetting = .calendarMonth

    private let expenseRepository: any ExpenseRepository
    private let categoryRepository: any CategoryRepository
    private let settingsRepository: any SettingsRepository

    public init(
        expenseRepository: any ExpenseRepository,
        categoryRepository: any CategoryRepository,
        settingsRepository: any SettingsRepository,
        anchor: Date = CalendarDay.today()
    ) {
        self.expenseRepository = expenseRepository
        self.categoryRepository = categoryRepository
        self.settingsRepository = settingsRepository
        self.anchor = anchor
    }

    public func load() async {
        isLoading = true
        errorMessage = nil
        do {
            setting = try await settingsRepository.settings().payPeriod
            let period = PayPeriodCalculator.period(containing: anchor, setting: setting)
            let previous = PayPeriodCalculator.previous(period, setting: setting)

            async let current = expenseRepository.expenses(in: period.range)
            async let earlier = expenseRepository.expenses(in: previous.range)
            async let allCategories = categoryRepository.categories()
            let (expenses, previousExpenses, categories) =
                try await (current, earlier, allCategories)

            summary = StatisticsBuilder.make(
                period: period,
                expenses: expenses,
                previousExpenses: previousExpenses,
                categories: Dictionary(
                    categories.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first }
                )
            )
        } catch {
            errorMessage = error.localizedDescription
            summary = .empty
        }
        isLoading = false
    }

    public func goToPrevious() async {
        let period = PayPeriodCalculator.period(containing: anchor, setting: setting)
        anchor = CalendarDay.adding(days: -1, to: period.start)
        await load()
    }

    public func goToNext() async {
        let period = PayPeriodCalculator.period(containing: anchor, setting: setting)
        anchor = period.end
        await load()
    }
}
