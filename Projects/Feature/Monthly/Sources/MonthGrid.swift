import SwiftUI
import DesignSystem
import Shared

struct MonthGrid: View {
    let month: Date
    let today: Date
    /// 탭 1이 보고 있는 날짜.
    let selectedDay: Date
    let total: (Date) -> Decimal?
    let onSelect: (Date) -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 2),
        count: 7
    )

    var body: some View {
        VStack(spacing: 0) {
            weekdayHeader
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(CalendarDay.monthGrid(containing: month).enumerated()), id: \.offset) { _, day in
                    if let day {
                        DayCell(
                            day: day,
                            total: total(day),
                            isToday: day == today,
                            isSelected: day == selectedDay,
                            onTap: { onSelect(day) }
                        )
                    } else {
                        Color.clear.frame(height: DayCell.height)
                    }
                }
            }
        }
        .padding(.horizontal, 2)
    }

    /// 요일은 모두 같은 색이다. 일요일은 달력 칸의 숫자에서만 구분한다.
    private var weekdayHeader: some View {
        HStack(spacing: 2) {
            ForEach(Array(CalendarDay.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(AppFont.caption)
                    .tracking(0.4)
                    .foregroundStyle(AppColor.textFaint)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, AppSpacing.sm)
    }
}

#Preview {
    MonthGrid(
        month: CalendarDay.today(),
        today: CalendarDay.today(),
        selectedDay: CalendarDay.today(),
        total: { _ in 43_200 },
        onSelect: { _ in }
    )
    .padding(.horizontal, AppSpacing.lg)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(AppColor.background)
}
