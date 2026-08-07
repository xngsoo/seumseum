//
//  ExpenseTests.swift
//  Domain
//
//  Created by SEUNGSOO HAN on 8/7/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation
import Testing
import Shared
@testable import Domain

@Suite("Expense")
struct ExpenseTests {

    private func instant(
        _ year: Int, _ month: Int, _ day: Int,
        _ hour: Int, _ minute: Int = 0, in zone: TimeZone
    ) throws -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        return try #require(
            calendar.date(
                from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
            )
        )
    }

    private var seoul: TimeZone {
        get throws { try #require(TimeZone(identifier: "Asia/Seoul")) }
    }

    @Test("make가 고른 날짜를 달력일로 정규화")
    func makeNormalized() throws {
        let seoul = try seoul
        let picked = try instant(2026, 8, 6, 21, 30, in: seoul)

        let expense = Expense.make(
            amount: 12_000, memo: "저녁", categoryID: UUID(),
            pickedDate: picked, timeZone: seoul
        )

        #expect(expense.date == CalendarDay.calendar.startOfDay(for: expense.date))
        #expect(CalendarDay.components(of: expense.date).day == 6)
        #expect(expense.sortOrder == 0)
    }

    @Test("id가 다르면 다른 항목")
    func identity() {
        let categoryID = UUID()
        let day = CalendarDay.today()
        let a = Expense(amount: 1_000, categoryID: categoryID, date: day)
        let b = Expense(amount: 1_000, categoryID: categoryID, date: day)
        #expect(a != b)
        #expect(a == a)
    }

    @Test("move도 고른 날짜를 달력일로 정규화")
    func moveNormalizes() throws {
        let seoul = try seoul
        var expense = Expense.make(
            amount: 5_000, categoryID: UUID(),
            pickedDate: try instant(2026, 8, 6, 12, in: seoul), timeZone: seoul
        )

        expense.move(to: try instant(2026, 9, 1, 23, 45, in: seoul), in: seoul)

        #expect(expense.date == CalendarDay.calendar.startOfDay(for: expense.date))
        let c = CalendarDay.components(of: expense.date)
        #expect(c.year == 2026)
        #expect(c.month == 9)
        #expect(c.day == 1)
    }

    @Test("move는 UTC 음수 오프셋 지역에서도 로컬 달력일을 따른다")
    func moveInNegativeOffsetZone() throws {
        let newYork = try #require(TimeZone(identifier: "America/New_York"))
        var expense = Expense.make(
            amount: 5_000, categoryID: UUID(),
            pickedDate: try instant(2026, 8, 1, 12, in: newYork), timeZone: newYork
        )

        expense.move(to: try instant(2026, 9, 1, 23, 45, in: newYork), in: newYork)

        #expect(CalendarDay.components(of: expense.date).day == 1)
        #expect(CalendarDay.components(of: expense.date).month == 9)
    }

    @Test("move는 날짜 외의 값을 바꾸지 않는다")
    func movePreservesOtherFields() throws {
        let seoul = try seoul
        let original = Expense.make(
            amount: 5_000, memo: "점심", categoryID: UUID(),
            pickedDate: try instant(2026, 8, 6, 12, in: seoul), timeZone: seoul
        )
        var moved = original
        moved.move(to: try instant(2026, 9, 1, 9, in: seoul), in: seoul)

        #expect(moved.id == original.id)
        #expect(moved.amount == original.amount)
        #expect(moved.memo == original.memo)
        #expect(moved.categoryID == original.categoryID)
        #expect(moved.createdAt == original.createdAt)
        #expect(moved.sortOrder == original.sortOrder)
        #expect(moved.date != original.date)
    }
}
