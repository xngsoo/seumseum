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
