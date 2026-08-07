//
//  PayPeriodTests.swift
//  Domain
//
//  Created by SEUNGSOO HAN on 8/7/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation
import Testing
import Shared
@testable import Domain

@Suite("PayPeriod")
struct PayPeriodTests {

    private func day(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        try #require(CalendarDay.date(year: year, month: month, day: day))
    }

    private func ymd(_ date: Date) -> String {
        let c = CalendarDay.components(of: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    // MARK: - 급여일 꺼짐

    @Test("급여일이 꺼져 있으면 주기는 달력상의 월")
    func calendarMonth() throws {
        let period = PayPeriodCalculator.period(
            containing: try day(2026, 8, 15), setting: .calendarMonth
        )
        #expect(ymd(period.start) == "2026-08-01")
        #expect(ymd(period.lastDay) == "2026-08-31")
    }

    // MARK: - 기본 동작

    @Test("25일 지급, 보정 없음 → 7/25 ~ 8/24")
    func basicPeriod() throws {
        let setting = PayPeriodSetting.payday(dayOfMonth: 25, adjustment: .none)
        let period = PayPeriodCalculator.period(containing: try day(2026, 8, 1), setting: setting)
        #expect(ymd(period.start) == "2026-07-25")
        #expect(ymd(period.lastDay) == "2026-08-24")
    }

    @Test("지급일 당일은 새 주기의 첫날")
    func paydayStartsNewPeriod() throws {
        let setting = PayPeriodSetting.payday(dayOfMonth: 25, adjustment: .none)
        let period = PayPeriodCalculator.period(containing: try day(2026, 8, 25), setting: setting)
        #expect(ymd(period.start) == "2026-08-25")
    }

    // MARK: - 주말 보정

    @Test("토요일 지급일 → 이전 영업일은 금요일")
    func saturdayToPreviousFriday() throws {
        // 2026-07-25 은 토요일
        let result = PayPeriodCalculator.payday(
            year: 2026, month: 7, dayOfMonth: 25, adjustment: .prevBusinessDay
        )
        #expect(ymd(try #require(result)) == "2026-07-24")
    }

    @Test("일요일 지급일 → 이전 영업일은 금요일")
    func sundayToPreviousFriday() throws {
        // 2026-10-25 는 일요일
        let result = PayPeriodCalculator.payday(
            year: 2026, month: 10, dayOfMonth: 25, adjustment: .prevBusinessDay
        )
        #expect(ymd(try #require(result)) == "2026-10-23")
    }

    @Test("토요일 지급일 → 다음 영업일은 월요일")
    func saturdayToNextMonday() throws {
        let result = PayPeriodCalculator.payday(
            year: 2026, month: 7, dayOfMonth: 25, adjustment: .nextBusinessDay
        )
        #expect(ymd(try #require(result)) == "2026-07-27")
    }

    @Test("보정 없음이면 주말이어도 그대로")
    func noAdjustmentKeepsWeekend() throws {
        let result = PayPeriodCalculator.payday(
            year: 2026, month: 7, dayOfMonth: 25, adjustment: .none
        )
        #expect(ymd(try #require(result)) == "2026-07-25")
    }

    // MARK: - 말일 보정

    @Test("31일 지급 + 2월 → 말일로 보정 후 주말 규칙")
    func clampToLastDayThenWeekend() throws {
        // 2026-02-28 은 토요일
        let none = PayPeriodCalculator.payday(
            year: 2026, month: 2, dayOfMonth: 31, adjustment: .none
        )
        #expect(ymd(try #require(none)) == "2026-02-28")

        let previous = PayPeriodCalculator.payday(
            year: 2026, month: 2, dayOfMonth: 31, adjustment: .prevBusinessDay
        )
        #expect(ymd(try #require(previous)) == "2026-02-27")
    }

    @Test("윤년 2월은 29일까지 인정")
    func leapYear() throws {
        let result = PayPeriodCalculator.payday(
            year: 2028, month: 2, dayOfMonth: 31, adjustment: .none
        )
        #expect(ymd(try #require(result)) == "2028-02-29")
    }

    // MARK: - 달 경계를 넘는 보정

    @Test("보정이 다음 달로 넘어가도 주기 판정이 맞다")
    func adjustmentCrossesIntoNextMonth() throws {
        // 2026-02-28(토) + nextBusinessDay → 2026-03-02
        let setting = PayPeriodSetting.payday(dayOfMonth: 31, adjustment: .nextBusinessDay)
        let februaryPayday = PayPeriodCalculator.payday(
            year: 2026, month: 2, dayOfMonth: 31, adjustment: .nextBusinessDay
        )
        #expect(ymd(try #require(februaryPayday)) == "2026-03-02")

        // 3/1 은 아직 이전 주기(1월 지급일 시작)에 속한다
        let period = PayPeriodCalculator.period(containing: try day(2026, 3, 1), setting: setting)
        #expect(ymd(period.start) == "2026-02-02")
        #expect(ymd(period.lastDay) == "2026-03-01")
    }

    @Test("보정이 이전 달로 넘어가도 주기 판정이 맞다")
    func adjustmentCrossesIntoPreviousMonth() throws {
        // 2026-08-01 은 토요일 → prevBusinessDay → 2026-07-31
        let setting = PayPeriodSetting.payday(dayOfMonth: 1, adjustment: .prevBusinessDay)
        let augustPayday = PayPeriodCalculator.payday(
            year: 2026, month: 8, dayOfMonth: 1, adjustment: .prevBusinessDay
        )
        #expect(ymd(try #require(augustPayday)) == "2026-07-31")

        let period = PayPeriodCalculator.period(containing: try day(2026, 7, 31), setting: setting)
        #expect(ymd(period.start) == "2026-07-31")
    }

    // MARK: - 연속성

    @Test("이전·다음 주기가 빈틈이나 겹침 없이 이어진다")
    func periodsAreContiguous() throws {
        let setting = PayPeriodSetting.payday(dayOfMonth: 31, adjustment: .prevBusinessDay)
        var period = PayPeriodCalculator.period(containing: try day(2026, 1, 15), setting: setting)

        for _ in 0 ..< 24 {
            let next = PayPeriodCalculator.next(period, setting: setting)
            #expect(next.start == period.end)
            #expect(period.start < period.end)
            #expect(PayPeriodCalculator.previous(next, setting: setting) == period)
            period = next
        }
    }

    @Test("모든 날짜는 정확히 하나의 주기에 속한다")
    func everyDayBelongsToExactlyOnePeriod() throws {
        let setting = PayPeriodSetting.payday(dayOfMonth: 25, adjustment: .prevBusinessDay)
        var cursor = try day(2026, 1, 1)
        let end = try day(2027, 1, 1)

        while cursor < end {
            let period = PayPeriodCalculator.period(containing: cursor, setting: setting)
            #expect(period.contains(cursor), "\(ymd(cursor)) 가 \(ymd(period.start))~\(ymd(period.lastDay)) 에 없음")
            cursor = CalendarDay.adding(days: 1, to: cursor)
        }
    }
}
