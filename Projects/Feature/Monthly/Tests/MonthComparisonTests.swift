import Foundation
import Testing
import Shared
@testable import Monthly

@Suite("지난달 같은 기간 비교")
struct MonthComparisonTests {

    private func day(_ year: Int, _ month: Int, _ dayOfMonth: Int) throws -> Date {
        try #require(CalendarDay.date(year: year, month: month, day: dayOfMonth))
    }

    /// `[일자: 금액]` 을 그 달의 날짜별 합계로 편다.
    private func totals(_ year: Int, _ month: Int, _ amounts: [Int: Decimal]) throws -> [Date: Decimal] {
        var result: [Date: Decimal] = [:]
        for (dayOfMonth, amount) in amounts {
            result[try day(year, month, dayOfMonth)] = amount
        }
        return result
    }

    @Test("이번 달은 오늘까지만 견준다")
    func currentMonthCutsAtToday() throws {
        let comparison = MonthComparison.make(
            month: try day(2026, 8, 1),
            today: try day(2026, 8, 13),
            currentTotalsByDay: try totals(2026, 8, [1: 10_000, 13: 5_000, 20: 99_000]),
            previousTotalsByDay: try totals(2026, 7, [1: 10_000, 13: 2_000, 25: 99_000])
        )

        // 14일 이후는 빠진다.
        #expect(comparison.currentTotal == 15_000)
        #expect(comparison.previousTotal == 12_000)
        #expect(comparison.deltaPercent == 25)
        #expect(comparison.isCurrentMonth)
        #expect(comparison.periodText == "8/1 – 8/13")
    }

    @Test("지난 달을 보고 있으면 그 달 전체를 견준다")
    func pastMonthComparesWholeMonth() throws {
        let comparison = MonthComparison.make(
            month: try day(2026, 7, 1),
            today: try day(2026, 8, 13),
            currentTotalsByDay: try totals(2026, 7, [1: 10_000, 31: 10_000]),
            previousTotalsByDay: try totals(2026, 6, [30: 25_000])
        )

        #expect(comparison.currentTotal == 20_000)
        #expect(comparison.previousTotal == 25_000)
        #expect(comparison.deltaPercent == -20)
        #expect(!comparison.isCurrentMonth)
        #expect(comparison.periodText == "7/1 – 7/31")
    }

    @Test("지난달이 더 짧으면 있는 날까지만 견준다")
    func shorterPreviousMonth() throws {
        let comparison = MonthComparison.make(
            month: try day(2026, 3, 1),
            today: try day(2026, 3, 31),
            currentTotalsByDay: try totals(2026, 3, [31: 10_000]),
            previousTotalsByDay: try totals(2026, 2, [28: 10_000])
        )

        // 2월은 28일까지뿐이라 그날 기록이 빠지지 않아야 한다.
        #expect(comparison.previousTotal == 10_000)
        #expect(comparison.deltaPercent == 0)
    }

    @Test("지난달에 기록이 없으면 비율을 내지 않는다")
    func noPreviousRecords() throws {
        let comparison = MonthComparison.make(
            month: try day(2026, 8, 1),
            today: try day(2026, 8, 13),
            currentTotalsByDay: try totals(2026, 8, [2: 30_000]),
            previousTotalsByDay: [:]
        )

        #expect(comparison.currentTotal == 30_000)
        #expect(comparison.deltaPercent == nil)
    }

    @Test("이번 달 기록이 없으면 그만큼 줄어든 것이다")
    func noCurrentRecords() throws {
        let comparison = MonthComparison.make(
            month: try day(2026, 8, 1),
            today: try day(2026, 8, 10),
            currentTotalsByDay: [:],
            previousTotalsByDay: try totals(2026, 7, [3: 40_000])
        )

        #expect(comparison.currentTotal == .zero)
        #expect(comparison.deltaPercent == -100)
    }
}
