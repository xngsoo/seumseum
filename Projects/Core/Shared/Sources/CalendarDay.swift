//
//  CalendarDay.swift
//  Shared
//
//  Created by SEUNGSOO HAN on 8/7/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation

public enum CalendarDay {
    
    /// 저장된 날짜 값을 해석할 때 사용하는 달력.
    /// 시간대는 UTC로 고정.
    public static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
    
    /// 기록 시간을 그 시점 로컬 달력일의 UTC 자정으로 변환.
    /// - Important: 입력은 실제 기록 시간이어야 함.
    public static func normalized(_ instant: Date, in timeZone: TimeZone = .current) -> Date {
        let offset = TimeInterval(timeZone.secondsFromGMT(for: instant))
        return calendar.startOfDay(for: instant + offset)
    }
    
    /// 로컬 기준 오늘.
    public static func today(in timeZone: TimeZone = .current) -> Date {
        return normalized(.now, in: timeZone)
    }
    
    /// 달력일 기준으로 날짜 이동.
    public static func adding(days: Int, to day: Date) -> Date {
        return calendar.date(byAdding: .day, value: days, to: day) ?? day
    }
    
    /// 표시에 필요한 구성요소. 원시 Date를 화면에 넘기지 않는다.
    public static func components(of day: Date) -> DateComponents {
        return calendar.dateComponents([.year, .month, .day, .weekday], from: day)
    }
    
    /// 그 날이 속한 달의 구간.
    /// 기간 조회에서 사용.
    public static func monthRange(containing day: Date) -> Range<Date> {
        guard let interval = calendar.dateInterval(of: .month, for: day) else {
            return day ..< adding(days: 1, to: day)
        }
        return interval.start ..< interval.end
    }
}

public extension CalendarDay {
    static func date(year: Int, month: Int, day: Int) -> Date? {
        return calendar.date(from: DateComponents(year: year, month: month, day: day))
    }
    
    static func startOfMonth(containing day: Date) -> Date {
        return monthRange(containing: day).lowerBound
    }
    
    static func adding(months: Int, to day: Date) -> Date {
        return calendar.date(byAdding: .month, value: months, to: day) ?? day
    }
    
    static func daysInMonth(year: Int, month: Int) -> Int? {
        guard let first = date(year: year, month: month, day: 1),
              let range = calendar.range(of: .day, in: .month, for: first)
        else { return nil }
        return range.count
    }
    
    /// 토, 일 여부 확인
    static func isWeekend(_ day: Date) -> Bool {
        let weekday = calendar.component(.weekday, from: day)
        return weekday == 1 || weekday == 7
    }
    
    /// 화면 상단의 날짜 표기
    static func headerText(_ day: Date) -> String {
        return headerFormatter.string(from: day)
    }
    
    private static let headerFormatter : DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        return formatter
    }()
}
