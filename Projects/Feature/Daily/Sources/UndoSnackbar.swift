import SwiftUI
import DesignSystem

struct UndoSnackbar: View {
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Text("1건 삭제됨")
                .font(AppFont.rowDetail)
                .foregroundStyle(AppColor.snackbarLabel)
            Spacer(minLength: 0)
            Button("실행취소", action: onUndo)
                .font(AppFont.rowDetail.weight(.semibold))
                .foregroundStyle(AppColor.accentUndo)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, 13)
        .background(
            AppColor.snackbarSurface,
            in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
        )
        .shadow(color: .black.opacity(0.18), radius: 10, y: 6)
    }
}

#Preview {
    UndoSnackbar {}
        .padding(18)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .background(AppColor.background)
}
