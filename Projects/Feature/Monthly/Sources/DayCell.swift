import SwiftUI
import DesignSystem
import Shared

struct DayCell: View {
    static let height: CGFloat = 56

    let day: Date
    let total: Decimal?
    let isToday: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(dayNumber)
                    .font(AppFont.rowDetail)
                    .foregroundStyle(numberColor)
                    .frame(width: 26, height: 26)
                    .background(isToday ? AppColor.accent : .clear, in: Circle())
                Text(totalText)
                    .font(AppFont.amountSmall)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Self.height)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
    }

    private var components: DateComponents { CalendarDay.components(of: day) }

    private var dayNumber: String { "\(components.day ?? 0)" }

    private var totalText: String {
        guard let total, total > .zero else { return " " }
        return AmountFormatter.short(total)
    }

    private var numberColor: Color {
        if isToday { return .white }
        switch components.weekday {
        case 1: return AppColor.category(.red)
        case 7: return AppColor.category(.blue)
        default: return AppColor.textPrimary
        }
    }

    private var accessibilityText: String {
        let prefix = isToday ? "오늘, " : ""
        guard let total, total > .zero else { return prefix + "\(dayNumber)일, 기록 없음" }
        return prefix + "\(dayNumber)일, \(AmountFormatter.full(total))"
    }
}
