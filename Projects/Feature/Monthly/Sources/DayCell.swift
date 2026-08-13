import SwiftUI
import DesignSystem
import Shared

struct DayCell: View {
    static let height: CGFloat = 62

    let day: Date
    let total: Decimal?
    let isToday: Bool
    /// 탭 1이 보고 있는 날짜. 옅은 배경으로 표시한다.
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 5) {
            Text(dayNumber)
                .font(AppFont.calendarDay)
                .foregroundStyle(numberColor)
            Text(totalText)
                .font(AppFont.calendarAmount)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.height, alignment: .top)
        .padding(.top, 7)
        .background(
            isSelected ? AppColor.accentSoft : .clear,
            in: RoundedRectangle(cornerRadius: 10)
        )
        .contentShape(Rectangle())
        // 스와이프로 달을 넘길 때 칸 안에서 손을 떼도 눌린 것으로 보지 않는다.
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(accessibilityText)
        .accessibilityAction { onTap() }
    }

    private var components: DateComponents { CalendarDay.components(of: day) }

    private var dayNumber: String { "\(components.day ?? 0)" }

    /// 기록이 없는 날은 숫자만 남긴다. 빈 문자열을 두어 칸 높이는 유지한다.
    private var totalText: String {
        guard let total, total > .zero else { return " " }
        return AmountFormatter.shortValue(total)
    }

    private var numberColor: Color {
        if isToday { return AppColor.accent }
        return components.weekday == 1 ? AppColor.category(.red) : AppColor.textPrimary
    }

    private var accessibilityText: String {
        let prefix = isToday ? "오늘, " : ""
        guard let total, total > .zero else { return prefix + "\(dayNumber)일, 기록 없음" }
        return prefix + "\(dayNumber)일, \(AmountFormatter.full(total))"
    }
}

#Preview {
    HStack(spacing: 2) {
        DayCell(day: CalendarDay.today(), total: 43_200, isToday: true, isSelected: false, onTap: {})
        DayCell(day: CalendarDay.today(), total: 9_500, isToday: false, isSelected: true, onTap: {})
        DayCell(day: CalendarDay.today(), total: nil, isToday: false, isSelected: false, onTap: {})
    }
    .padding()
    .background(AppColor.background)
}
