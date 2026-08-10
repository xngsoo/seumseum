import SwiftUI
import DesignSystem
import Shared

struct MonthlyHeader: View {
    let month: Date
    let total: Decimal
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.sm) {
                stepButton(systemImage: "chevron.left", label: "이전 달", action: onPrevious)
                Spacer()
                Text(CalendarDay.monthText(month))
                    .font(AppFont.screenTitle)
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                stepButton(systemImage: "chevron.right", label: "다음 달", action: onNext)
            }
            Text(AmountFormatter.full(total))
                .font(AppFont.amountLarge)
                .foregroundStyle(AppColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.screenMargin)
        .padding(.vertical, AppSpacing.lg)
        .background(AppColor.surface)
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
    MonthlyHeader(month: CalendarDay.today(), total: 1_535_000, onPrevious: {}, onNext: {})
}
