//
//  PayPeriodCalculator.swift
//  Domain
//
//  Created by SEUNGSOO HAN on 8/7/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation
import Shared

public enum PayPeriodCalculator {

    public static func period(containing day: Date, setting: PayPeriodSetting) -> PayPeriod {
        switch setting {
        case .calendarMonth:
            let month = CalendarDay.monthRange(containing: day)
            return PayPeriod(start: month.lowerBound, end: month.upperBound)

        case let .payday(paydayDay, adjustment):
            let candidates = paydays(around: day, paydayDay: paydayDay, adjustment: adjustment)
            guard let index = candidates.lastIndex(where: { $0 <= day }),
                  index + 1 < candidates.count
            else {
                let month = CalendarDay.monthRange(containing: day)
                return PayPeriod(start: month.lowerBound, end: month.upperBound)
            }
            return PayPeriod(start: candidates[index], end: candidates[index + 1])
        }
    }

    public static func next(_ period: PayPeriod, setting: PayPeriodSetting) -> PayPeriod {
        self.period(containing: period.end, setting: setting)
    }

    public static func previous(_ period: PayPeriod, setting: PayPeriodSetting) -> PayPeriod {
        self.period(containing: CalendarDay.adding(days: -1, to: period.start), setting: setting)
    }

    public static func payday(
        year: Int, month: Int, day paydayDay: PaydayDay, adjustment: PaydayAdjustment
    ) -> Date? {
        guard let daysInMonth = CalendarDay.daysInMonth(year: year, month: month) else { return nil }
        let resolved = paydayDay.resolved(daysInMonth: daysInMonth)
        guard let base = CalendarDay.date(year: year, month: month, day: resolved) else { return nil }
        return adjusted(base, by: adjustment)
    }

    private static func adjusted(_ base: Date, by adjustment: PaydayAdjustment) -> Date {
        guard CalendarDay.isWeekend(base) else { return base }
        let isSaturday = CalendarDay.components(of: base).weekday == 7
        switch adjustment {
        case .none:
            return base
        case .prevBusinessDay:
            return CalendarDay.adding(days: isSaturday ? -1 : -2, to: base)
        case .nextBusinessDay:
            return CalendarDay.adding(days: isSaturday ? 2 : 1, to: base)
        }
    }

    private static func paydays(
        around day: Date, paydayDay: PaydayDay, adjustment: PaydayAdjustment
    ) -> [Date] {
        let anchor = CalendarDay.startOfMonth(containing: day)
        return (-2 ... 2).compactMap { offset -> Date? in
            let month = CalendarDay.adding(months: offset, to: anchor)
            let parts = CalendarDay.components(of: month)
            guard let year = parts.year, let monthNumber = parts.month else { return nil }
            return payday(
                year: year, month: monthNumber,
                day: paydayDay, adjustment: adjustment
            )
        }
        .sorted()
    }
}
