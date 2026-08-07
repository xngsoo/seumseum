//
//  CalendarDayTests.swift
//  Shared
//
//  Created by SEUNGSOO HAN on 8/7/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation
import Testing
import Shared

@Suite("CalendarDay")
struct CalendarDayTests {
    
    private func instant(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, in zone: String) throws -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: zone))
        return try #require(calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour)))
    }
    
    private func ymd(_ day: Date) -> String {
        let calendar = CalendarDay.components(of: day)
        return String(format: "%04d-%02d-%02d", calendar.year ?? 0, calendar.month ?? 0, calendar.day ?? 0)
    }
    
    @Test("서울에서 기록한 날짜는 뉴욕에서도 동일")
    func stableAcrossTimeZone() throws {
        let seoul = try #require(TimeZone(identifier: "Asia/Seoul"))
        let recorded = try instant(2026, 8, 6, 10, in: "Asia/Seoul")
        let stored = CalendarDay.normalized(recorded, in: seoul)
        #expect(ymd(stored) == "2026-08-06")
    }
    
    @Test("자정 직후 기록도 로컬 달력일을 따른다")
    func afterMidnight() throws {
        let seoul = try #require(TimeZone(identifier: "Asia/Seoul"))
        let recorded = try instant(2026, 8, 7, 0, in: "Asia/Seoul")
        #expect(ymd(CalendarDay.normalized(recorded, in: seoul)) == "2026-08-07")
    }
    
    @Test("UTC 음수 오프셋 지역도 로컬 달력일을 따른다")
    func negativeOffsetZone() throws {
        let newYork = try #require(TimeZone(identifier: "America/New_York"))
        let recorded = try instant(2026, 8, 6, 23, in: "America/New_York")
        #expect(ymd(CalendarDay.normalized(recorded, in: newYork)) == "2026-08-06")
    }
    
    @Test("정규화 결과는 UTC 자정")
    func isUTCMidnight() throws {
        let seoul = try #require(TimeZone(identifier: "Asia/Seoul"))
        let stored = CalendarDay.normalized(try instant(2026, 8, 6, 9, in: "Asia/Seoul"))
        #expect(stored == CalendarDay.calendar.startOfDay(for: stored))
        #expect(stored.timeIntervalSince1970.truncatingRemainder(dividingBy: 86_400) == 0)
    }
    
    @Test("같은 날의 다른 시간은 같은 값")
    func sameDayDiffTime() throws {
        let seoul = try #require(TimeZone(identifier: "Asia/Seoul"))
        let morning = CalendarDay.normalized(try instant(2026, 8, 6, 1, in: "Asia/Seoul"), in: seoul)
        let evening = CalendarDay.normalized(try instant(2026, 8, 6, 23, in: "Asia/Seoul"), in: seoul)
        #expect(morning == evening)
    }
    
    @Test("날짜 이동")
    func addingDays() throws {
        let seoul = try #require(TimeZone(identifier: "Asia/Seoul"))
        let day = CalendarDay.normalized(try instant(2026, 8, 31, 12, in: "Asia/Seoul"), in: seoul)
        #expect(ymd(CalendarDay.adding(days: 1, to: day)) == "2026-09-01")
        #expect(ymd(CalendarDay.adding(days: -1, to: day)) == "2026-08-30")
    }
    
    @Test("월 범위는 1일부터 다음 달 1일 직전")
    func monthRange() throws {
        let seoul = try #require(TimeZone(identifier: "Asia/Seoul"))
        let day = CalendarDay.normalized(try instant(2026, 8, 15, 12, in: "Asia/Seoul"), in: seoul)
        let range = CalendarDay.monthRange(containing: day)
        #expect(ymd(range.lowerBound) == "2026-08-01")
        #expect(ymd(range.upperBound) == "2026-09-01")
        #expect(range.contains(day))
    }
    
    @Test("월 이동은 없는 날짜를 그 달 마지막 날로 맞춘다")
    func addingMonthsClamps() throws {
        let day = try #require(CalendarDay.date(year: 2026, month: 8, day: 31))
        let next = CalendarDay.adding(months: 1, to: day)
        #expect(CalendarDay.components(of: next).day == 30)   // 9월은 30일까지
    }

    @Test("주말 판정은 토·일만")
    func weekend() throws {
        // 2026-07-25 토, 26 일, 27 월
        #expect(CalendarDay.isWeekend(try #require(CalendarDay.date(year: 2026, month: 7, day: 25))))
        #expect(CalendarDay.isWeekend(try #require(CalendarDay.date(year: 2026, month: 7, day: 26))))
        #expect(!CalendarDay.isWeekend(try #require(CalendarDay.date(year: 2026, month: 7, day: 27))))
    }

    @Test("평년·윤년 2월 일수")
    func daysInFebruary() {
        #expect(CalendarDay.daysInMonth(year: 2026, month: 2) == 28)
        #expect(CalendarDay.daysInMonth(year: 2028, month: 2) == 29)
        #expect(CalendarDay.daysInMonth(year: 2100, month: 2) == 28)   // 100년 예외
    }
}

