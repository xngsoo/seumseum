import SwiftUI
import DesignSystem

struct EditorSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
