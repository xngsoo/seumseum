import SwiftUI
import DesignSystem

struct BootstrapFailureView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(AppColor.textSecondary)
            Text("데이터를 불러오지 못했습니다")
                .font(AppFont.screenTitle)
                .foregroundStyle(AppColor.textPrimary)
            Text(message)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
            Button("다시 시도", action: onRetry)
                .font(AppFont.rowTitle)
                .tint(AppColor.accent)
        }
        .padding(AppSpacing.screenMargin)
    }
}

#Preview {
    BootstrapFailureView(message: "저장소에 접근하지 못했습니다.") {}
}
