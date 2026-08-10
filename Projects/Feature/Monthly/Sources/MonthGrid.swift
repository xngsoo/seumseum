import SwiftUI
import DesignSystem
import Shared

struct MonthGrid: View {
    let month: Date
    let today: Date
    let total: (Date) -> Decimal?
    let onSelect: (Date) -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 0),
        count: 7
    )

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            weekdayHeader
            LazyVGrid(columns: columns, spacing: AppSpacing.xs) {
                ForEach(Array(CalendarDay.monthGrid(containing: month).enumerated()), id: \.offset) { _, day in
                    if let day {
                        DayCell(
                            day: day,
                            total: total(day),
                            isToday: day == today,
                            onTap: { onSelect(day) }
                        )
                    } else {
                        Color.clear.frame(height: DayCell.height)
                    }
                }
            }
        }
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(Array(CalendarDay.weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                Text(symbol)
                    .font(AppFont.caption)
                    .foregroundStyle(weekdayColor(index))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func weekdayColor(_ index: Int) -> Color {
        switch index {
        case 0: AppColor.category(.red)
        case 6: AppColor.category(.blue)
        default: AppColor.textSecondary
        }
    }
}
