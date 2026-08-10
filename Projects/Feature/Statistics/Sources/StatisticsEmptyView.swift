import SwiftUI
import DesignSystem

struct StatisticsEmptyView: View {
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "chart.pie")
                .font(.system(size: 40))
                .foregroundStyle(AppColor.separator)
            Text("이 주기에는 기록이 없어요")
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textPrimary)
            Text("지출을 추가하면 여기에 요약이 보입니다")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl * 2)
    }
}

#Preview {
    StatisticsEmptyView()
}
