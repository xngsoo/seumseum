import SwiftUI
import DesignSystem
import Domain

struct CategoryPicker: View {
    let categories: [ExpenseCategory]
    @Binding var selection: UUID?

    /// 4열 고정. ExpenseCategory.maxCount(12) 까지 3줄에 담긴다.
    private static let columnCount = 4
    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: AppSpacing.sm),
        count: columnCount
    )

    var body: some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.md) {
            ForEach(categories.prefix(ExpenseCategory.maxCount)) { category in
                cell(category)
            }
        }
    }

    private func cell(_ category: ExpenseCategory) -> some View {
        let isSelected = selection == category.id
        return Button {
            selection = category.id
        } label: {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: category.symbolName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : AppColor.category(category.colorToken))
                    .frame(width: 44, height: 44)
                    .background(
                        isSelected
                            ? AppColor.category(category.colorToken)
                            : AppColor.surface,
                        in: RoundedRectangle(cornerRadius: AppSpacing.md)
                    )
                Text(category.name)
                    .font(AppFont.caption)
                    .foregroundStyle(isSelected ? AppColor.textPrimary : AppColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.name)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
