import SwiftUI
import DesignSystem

struct DailyEmptyView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: AppSpacing.md) {
            Text("기록이 없는 날입니다")
                .font(AppFont.rowDetail)
                .foregroundStyle(AppColor.textFaint)
            Text("아래 추가버튼으로 지출을 추가해보세요")
                .font(AppFont.rowCaption)
                .foregroundStyle(AppColor.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 76)
    }
}

#Preview {
    DailyEmptyView(onAdd: {})
        .frame(maxHeight: .infinity)
        .background(AppColor.background)
}
