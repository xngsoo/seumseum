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
        let categories = try await stack.categories.categories()
        guard !categories.isEmpty else { return }

        let plan: [(Date, [(String, Decimal, Int)])] = [
            (today, [
                ("점심 김치찌개", 9_500, 0),
                ("아메리카노", 4_800, 1),
                ("지하철", 1_550, 2),
                ("장보기", 43_200, 4),
                ("영화", 15_000, 6),
            ]),
            (yesterday, [
                ("편의점", 3_200, 4),
                ("택시", 12_800, 2),
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
