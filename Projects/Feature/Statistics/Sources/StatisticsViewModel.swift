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

    /// 무엇을 기준으로 끊은 주기인지. 화면 제목 아래에 작게 붙는다.
    /// 통계만 급여 주기를 쓰므로, 여기 적어 두지 않으면 왜 1일부터가 아닌지 알 수 없다.
    public var basisText: String {
        switch setting {
        case .calendarMonth:
            "달력 기준 · 1일~말일"
        case let .payday(day, _):
            switch day {
            case let .day(value): "급여 주기 · 매월 \(value)일"
            case .lastDay: "급여 주기 · 매월 말일"
            }
        }
    }

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

    /// 오늘이 든 주기로 돌아온다.
    public func goToCurrentPeriod() async {
        anchor = CalendarDay.today()
        await load()
    }

    public func goToNext() async {
        let period = PayPeriodCalculator.period(containing: anchor, setting: setting)
        anchor = period.end
        await load()
    }
}
