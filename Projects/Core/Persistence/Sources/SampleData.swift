#if DEBUG
import Foundation
import Domain
import Shared

/// 실행 인자 `-seedSampleData` 가 켜져 있을 때만 표본 데이터를 넣는다.
/// 릴리스 빌드에는 포함되지 않는다.
public enum SampleData {

    public static var isRequested: Bool {
        ProcessInfo.processInfo.arguments.contains("-seedSampleData")
    }

    public static func seedIfRequested(into stack: PersistenceStack) async throws {
        guard isRequested else { return }

        let today = CalendarDay.today()
        let yesterday = CalendarDay.adding(days: -1, to: today)
        let earlier = CalendarDay.adding(days: -12, to: today)
        let lastMonth = CalendarDay.adding(days: -34, to: today)
        let categories = try await stack.categories.categories()
        guard !categories.isEmpty else { return }

        let plan: [(Date, [(String, Decimal, Int)])] = [
            // 오늘 날짜는 목록이 화면을 넘치도록 넉넉히 넣는다.
            // 스크롤과 드래그 자동 스크롤을 눈으로 확인하려면 한 화면에 다 들어오면 안 된다.
            (today, [
                ("점심 김치찌개", 9_500, 1),
                ("아메리카노", 4_800, 1),
                ("지하철", 1_550, 2),
                ("장보기", 43_200, 0),
                ("영화", 15_000, 3),
                ("편의점", 3_300, 0),
                ("택시", 12_800, 2),
                ("약국", 8_400, 4),
                ("서점", 21_000, 3),
                ("카페 라떼", 5_500, 1),
                ("주유", 60_000, 2),
                ("문구", 6_700, 5),
            ]),
            (yesterday, [
                ("편의점", 3_200, 4),
                ("택시", 12_800, 2),
            ]),
            (earlier, [
                ("병원", 28_000, 5),
                ("책", 18_500, 6),
                ("주유", 60_000, 2),
            ]),
            (lastMonth, [
                ("지난달 외식", 52_000, 0),
                ("지난달 쇼핑", 88_000, 3),
            ]),
        ]

        for (day, samples) in plan {
            guard try await stack.expenses.expenses(on: day).isEmpty else { continue }
            for (memo, amount, categoryIndex) in samples.reversed() {
                let category = categories[min(categoryIndex, categories.count - 1)]
                try await stack.expenses.insert(
                    Expense(amount: amount, memo: memo, categoryID: category.id, date: day),
                    at: 0
                )
            }
        }
    }
}
#endif
