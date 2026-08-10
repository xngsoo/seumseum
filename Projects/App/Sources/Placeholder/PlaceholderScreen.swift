import SwiftUI
import DesignSystem

struct PlaceholderScreen: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Text(title)
                .font(AppFont.screenTitle)
                .foregroundStyle(AppColor.textPrimary)
            Text(detail)
                .font(AppFont.rowDetail)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    PlaceholderScreen(title: "일별", detail: "탭 1 — 그날의 소비 내역")
}
