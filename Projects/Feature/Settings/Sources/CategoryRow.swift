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
                .lineLimit(1)
            Spacer()
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    CategoryRow(
        category: ExpenseCategory(
            name: "주거/생활", symbolName: "house.fill", colorToken: .green, isBuiltIn: true
        )
    )
    .padding(.horizontal, AppSpacing.screenMargin)
    .frame(height: 56)
    .background(AppColor.surface)
}
