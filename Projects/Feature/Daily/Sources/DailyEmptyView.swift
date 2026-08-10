import SwiftUI
import DesignSystem

struct DailyEmptyView: View {
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(AppColor.separator)
            Text("이 날은 기록이 없어요")
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textPrimary)
            Text("아래 + 버튼으로 지출을 추가해 보세요")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(DaySwipeGesture(onPrevious: onPrevious, onNext: onNext).gesture)
    }
}

#Preview {
    DailyEmptyView(onPrevious: {}, onNext: {})
}
