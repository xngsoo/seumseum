import SwiftUI
import DesignSystem
import Domain

struct CategoryRow: View {
    let category: ExpenseCategory

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: category.symbolName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(
                    AppColor.category(category.colorToken),
                    in: RoundedRectangle(cornerRadius: AppSpacing.sm)
                )
            Text(category.name)
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textPrimary)
            if category.isBuiltIn {
                Text("기본")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 2)
                    .background(AppColor.background, in: Capsule())
            }
            Spacer()
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    CategoryRow(
        category: ExpenseCategory(
            name: "식비", symbolName: "fork.knife", colorToken: .orange, isBuiltIn: true
        )
    )
}
