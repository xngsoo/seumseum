import SwiftUI
import DesignSystem
import Shared

/// 탭 3 상단. 어느 기간을 보고 있는지 늘 밝힌다.
struct StatisticsHeader: View {
    let periodText: String
    let basisText: String
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            stepButton(systemImage: "chevron.left", label: "이전 주기", action: onPrevious)
            Spacer()
            VStack(spacing: 2) {
                Text(periodText)
                    .font(AppFont.periodTitle)
                    .foregroundStyle(AppColor.textPrimary)
                Text(basisText)
                    .font(AppFont.overline)
                    .tracking(0.3)
                    .foregroundStyle(AppColor.textFaint)
            }
            Spacer()
            stepButton(systemImage: "chevron.right", label: "다음 주기", action: onNext)
        }
        .frame(height: 34)
        .accessibilityElement(children: .contain)
    }

    private func stepButton(
        systemImage: String, label: String, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppColor.textFaint)
                .frame(width: 34, height: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

#Preview {
    VStack {
        StatisticsHeader(
            periodText: "7/25 – 8/24",
            basisText: "급여 주기 · 매월 25일",
            onPrevious: {},
            onNext: {}
        )
        Spacer()
    }
    .padding(.horizontal, AppSpacing.screenMargin)
    .background(AppColor.background)
}
