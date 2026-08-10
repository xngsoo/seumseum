import Foundation
import Domain
import Shared

/// 카테고리 하나가 차지하는 몫.
public struct CategoryShare: Identifiable, Hashable, Sendable {
    public let category: ExpenseCategory
    public let amount: Decimal
    /// 0…1
    public let ratio: Double

    public var id: UUID { category.id }
}

/// 주기 안의 한 주.
public struct WeeklyTotal: Identifiable, Hashable, Sendable {
    /// 1부터 시작하는 주차
    public let week: Int
    public let range: Range<Date>
    public let amount: Decimal

    public var id: Int { week }
    public var label: String { "\(week)주" }
}

/// 한 주기의 통계.
public struct StatisticsSummary: Equatable, Sendable {
    public let period: PayPeriod
    public let total: Decimal
    public let previousTotal: Decimal
    public let dailyAverage: Decimal
    public let categoryShares: [CategoryShare]
    public let weeklyTotals: [WeeklyTotal]

    public static let empty = StatisticsSummary(
        period: PayPeriod(start: .distantPast, end: .distantPast),
        total: .zero, previousTotal: .zero, dailyAverage: .zero,
        categoryShares: [], weeklyTotals: []
    )

    /// 직전 주기 대비 증감액. 직전이 0이면 비교 대상이 없다.
    public var change: Decimal { total - previousTotal }

    public var hasComparison: Bool { previousTotal > .zero }

    /// 직전 대비 증감률(0.15 = 15% 증가). 비교 대상이 없으면 nil.
    public var changeRatio: Double? {
        guard hasComparison else { return nil }
        return NSDecimalNumber(decimal: change).doubleValue
            / NSDecimalNumber(decimal: previousTotal).doubleValue
    }

    public var topCategory: CategoryShare? { categoryShares.first }

    public var isEmpty: Bool { total == .zero }

    /// 화면 상단에 쓰는 적용 기간. `7/25 – 8/24`
    public var periodText: String {
        "\(CalendarDay.shortText(period.start)) – \(CalendarDay.shortText(period.lastDay))"
    }
}
