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
    
    /// 화면 표기에 사용하는 Locale
    static let locale = Locale(identifier: "ko_KR")
    
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

public extension CalendarDay {

    /// 월 표기. `2026년 8월`
    static func monthText(_ day: Date) -> String {
        monthFormatter.string(from: day)
    }

    /// 그 달 1일이 무슨 요일인지 (일=1 … 토=7)
    static func firstWeekday(ofMonthContaining day: Date) -> Int {
        calendar.component(.weekday, from: startOfMonth(containing: day))
    }

    /// 달력 그리드용 날짜 배열. 앞쪽 빈 칸은 nil 로 채운다.
    static func monthGrid(containing day: Date) -> [Date?] {
        let range = monthRange(containing: day)
        let leading = firstWeekday(ofMonthContaining: day) - 1
        var cells: [Date?] = Array(repeating: nil, count: leading)
        var cursor = range.lowerBound
        while cursor < range.upperBound {
            cells.append(cursor)
            cursor = adding(days: 1, to: cursor)
        }
        return cells
    }

    /// 요일 머리글. 일요일부터 시작한다.
    static let weekdaySymbols: [String] = {
        var formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        return formatter.veryShortStandaloneWeekdaySymbols ?? ["일", "월", "화", "수", "목", "금", "토"]
    }()

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = locale
        formatter.dateFormat = "yyyy년 M월"
        return formatter
    }()
}

public extension CalendarDay {
    
    /// 반개구간에 들어있는 달력일 수
    static func dayCount(in range: Range<Date>) -> Int {
        return calendar.dateComponents([.day], from: range.lowerBound, to: range.upperBound).day ?? 0
    }
    
    /// 기간 표기에 쓰는 짧은 날짜. '7/25'
    static func shortText(_ day: Date) -> String {
        let parts = components(of: day)
        return "\(parts.month ?? 0)/\(parts.day ?? 0)"
    }
}
