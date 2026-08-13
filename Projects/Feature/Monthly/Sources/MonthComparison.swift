import Foundation
import Domain
import Shared

/// 지난달 같은 기간과의 지출 비교.
///
/// 이번 달을 보고 있으면 `1일 ~ 오늘` 을, 지난 달을 보고 있으면 그 달 전체를 견준다.
/// 이번 달은 아직 끝나지 않아서 달 전체끼리 견주면 언제나 줄어든 것처럼 보인다.
struct MonthComparison: Equatable, Sendable {

    /// 견준 구간. `8/1 – 8/13`
    let periodText: String
    /// 보고 있는 달에서 견준 구간의 합계.
    let currentTotal: Decimal
    /// 지난달 같은 구간의 합계.
    let previousTotal: Decimal
    /// 지난달 대비 증감률(%). 지난달에 기록이 없으면 견줄 수 없어 nil.
    let deltaPercent: Int?
    /// 보고 있는 달이 이번 달인지. 화면 문구가 달라진다.
    let isCurrentMonth: Bool

    static func make(
        month: Date,
        today: Date,
        currentTotalsByDay: [Date: Decimal],
        previousTotalsByDay: [Date: Decimal]
    ) -> MonthComparison {
        let monthStart = CalendarDay.startOfMonth(containing: month)
        let previousStart = CalendarDay.startOfMonth(
            containing: CalendarDay.adding(months: -1, to: monthStart)
        )
        let isCurrentMonth = monthStart == CalendarDay.startOfMonth(containing: today)

        // 이번 달이면 오늘까지, 아니면 그 달 전체를 자른다.
        let lastDay = isCurrentMonth
            ? (CalendarDay.components(of: today).day ?? 1)
            : daysInMonth(monthStart)

        let current = sum(currentTotalsByDay, from: monthStart, throughDay: lastDay)
        // 지난달이 더 짧으면 있는 날까지만 견준다. (3/31 ↔ 2월)
        let previous = sum(
            previousTotalsByDay,
            from: previousStart,
            throughDay: min(lastDay, daysInMonth(previousStart))
        )

        return MonthComparison(
            periodText: periodText(from: monthStart, throughDay: lastDay),
            currentTotal: current,
            previousTotal: previous,
            deltaPercent: delta(current: current, previous: previous),
            isCurrentMonth: isCurrentMonth
        )
    }

    private static func sum(
        _ totals: [Date: Decimal], from start: Date, throughDay lastDay: Int
    ) -> Decimal {
        (0 ..< lastDay).reduce(Decimal.zero) { running, offset in
            running + (totals[CalendarDay.adding(days: offset, to: start)] ?? .zero)
        }
    }

    private static func daysInMonth(_ monthStart: Date) -> Int {
        CalendarDay.dayCount(in: CalendarDay.monthRange(containing: monthStart))
    }

    private static func periodText(from start: Date, throughDay lastDay: Int) -> String {
        let last = CalendarDay.adding(days: lastDay - 1, to: start)
        return "\(CalendarDay.shortText(start)) – \(CalendarDay.shortText(last))"
    }

    /// 반올림한 정수 퍼센트. 지난달이 0이면 비율을 낼 수 없다.
    private static func delta(current: Decimal, previous: Decimal) -> Int? {
        guard previous > .zero else { return nil }
        let ratio = (current - previous) / previous * 100
        var rounded = Decimal()
        var value = ratio
        NSDecimalRound(&rounded, &value, 0, .plain)
        return NSDecimalNumber(decimal: rounded).intValue
    }
}
