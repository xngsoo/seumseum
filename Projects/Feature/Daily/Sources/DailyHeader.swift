import SwiftUI
import DesignSystem
import Shared

struct DailyHeader: View {
    let day: Date
    let total: Decimal
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: AppSpacing.xs) {
            dayRow
            Text(AmountFormatter.full(total))
                .font(AppFont.amountLarge)
                .foregroundStyle(AppColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.screenMargin)
        .padding(.vertical, AppSpacing.lg)
        .background(AppColor.surface)
        .contentShape(Rectangle())
        .gesture(DaySwipeGesture(onPrevious: onPrevious, onNext: onNext).gesture)
    }

    private var dayRow: some View {
        HStack(spacing: AppSpacing.sm) {
            stepButton(systemImage: "chevron.left", label: "이전 날짜", action: onPrevious)
            Spacer()
            Text(CalendarDay.headerText(day))
                .font(AppFont.screenTitle)
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
            stepButton(systemImage: "chevron.right", label: "다음 날짜", action: onNext)
        }
    }

    private func stepButton(
        systemImage: String, label: String, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColor.textSecondary)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

#Preview {
    DailyHeader(day: CalendarDay.today(), total: 152_300, onPrevious: {}, onNext: {})
}
