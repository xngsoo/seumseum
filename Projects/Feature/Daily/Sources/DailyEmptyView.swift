import SwiftUI
import DesignSystem

struct DailyEmptyView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Circle()
                .strokeBorder(
                    AppColor.dashedStroke,
                    style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                )
                .frame(width: 44, height: 44)
            Text("기록이 없는 날입니다")
                .font(AppFont.rowDetail)
                .foregroundStyle(AppColor.textFaint)
            Button(action: onAdd) {
                Label("지출 추가", systemImage: "plus")
                    .font(AppFont.rowCaption)
                    .foregroundStyle(AppColor.accentInk)
                    .padding(.vertical, 6)
                    .padding(.horizontal, AppSpacing.xs)
            }
            .buttonStyle(.plain)
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
