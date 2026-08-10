import SwiftUI
import DesignSystem

struct UndoSnackbar: View {
    let onUndo: () -> Void

    var body: some View {
        HStack {
            Text("항목을 삭제했습니다")
                .font(AppFont.rowDetail)
                .foregroundStyle(AppColor.surface)
            Spacer(minLength: AppSpacing.md)
            Button("취소", action: onUndo)
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.accent)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .background(AppColor.textPrimary, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
    }
}

#Preview {
    UndoSnackbar {}
}
