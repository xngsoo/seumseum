import SwiftUI
import DesignSystem
import Shared

/// 탭 2 상단. 달력과 함께 스크롤된다.
struct MonthlyHeader: View {
    let month: Date
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            stepButton(systemImage: "chevron.left", label: "이전 달", action: onPrevious)
            Spacer()
            Text(CalendarDay.monthText(month))
                .font(AppFont.navTitle)
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
            stepButton(systemImage: "chevron.right", label: "다음 달", action: onNext)
        }
        .frame(height: 34)
        .padding(.horizontal, 6)
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
        MonthlyHeader(month: CalendarDay.today(), onPrevious: {}, onNext: {})
        Spacer()
    }
    .padding(.horizontal, AppSpacing.lg)
    .background(AppColor.background)
}
