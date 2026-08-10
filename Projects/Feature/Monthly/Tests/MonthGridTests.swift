import Foundation
import Testing
import Shared

@Suite("월 그리드")
struct MonthGridTests {

    private func day(_ y: Int, _ m: Int, _ d: Int) throws -> Date {
        try #require(CalendarDay.date(year: y, month: m, day: d))
    }

    @Test("앞쪽 빈 칸은 그 달 1일의 요일만큼이다")
    func leadingBlanks() throws {
        // 2026-08-01 은 토요일 → 앞에 빈 칸 6개
        let cells = CalendarDay.monthGrid(containing: try day(2026, 8, 15))
        #expect(cells.prefix(6).allSatisfy { $0 == nil })
        #expect(cells[6] == (try day(2026, 8, 1)))
    }

    @Test("칸 수는 빈 칸 + 그 달 일수와 같다")
    func cellCount() throws {
        let cells = CalendarDay.monthGrid(containing: try day(2026, 2, 10))
        let days = try #require(CalendarDay.daysInMonth(year: 2026, month: 2))
        #expect(days == 28)
        #expect(cells.count == 28 + (CalendarDay.firstWeekday(ofMonthContaining: try day(2026, 2, 1)) - 1))
        #expect(cells.compactMap { $0 }.count == days)
    }

    @Test("월 표기")
    func monthText() throws {
        #expect(CalendarDay.monthText(try day(2026, 8, 10)) == "2026년 8월")
    }

    @Test("요일 머리글은 일요일부터 7개")
    func weekdaySymbols() {
        #expect(CalendarDay.weekdaySymbols.count == 7)
        #expect(CalendarDay.weekdaySymbols.first == "일")
    }
}
