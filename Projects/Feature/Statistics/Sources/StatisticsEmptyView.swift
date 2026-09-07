import SwiftUI
import DesignSystem

struct StatisticsEmptyView: View {
    var body: some View {
        VStack(alignment: .center, spacing: AppSpacing.md) {
            Text("이 주기에는 기록이 없습니다")
                .font(AppFont.rowDetail)
                .foregroundStyle(AppColor.textFaint)
            Text("지출을 추가하면 통계를 확인할 수 있습니다")
                .font(AppFont.rowCaption)
                .foregroundStyle(AppColor.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 76)
    }
}

#Preview {
    StatisticsEmptyView()
        .frame(maxHeight: .infinity, alignment: .top)
        .background(AppColor.background)
}
