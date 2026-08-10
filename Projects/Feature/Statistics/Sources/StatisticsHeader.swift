import SwiftUI
import DesignSystem
import Shared

struct StatisticsHeader: View {
    let periodText: String
    let total: Decimal
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.sm) {
                stepButton(systemImage: "chevron.left", label: "이전 주기", action: onPrevious)
                Spacer()
                Text(periodText)
                    .font(AppFont.screenTitle)
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                stepButton(systemImage: "chevron.right", label: "다음 주기", action: onNext)
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
    StatisticsHeader(periodText: "7/25 – 8/24", total: 1_535_000, onPrevious: {}, onNext: {})
}
