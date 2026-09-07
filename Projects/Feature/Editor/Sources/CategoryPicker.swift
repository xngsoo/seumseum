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
        LazyVGrid(columns: columns, spacing: 9) {
            ForEach(categories.prefix(ExpenseCategory.maxCount)) { category in
                cell(category)
            }
        }
    }

    private func cell(_ category: ExpenseCategory) -> some View {
        let isSelected = selection == category.id
        let tint = AppColor.category(category.colorToken)

        return Button {
            selection = category.id
        } label: {
            VStack(spacing: 6) {
                Image(systemName: category.symbolName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(tint)
                    .frame(width: 32, height: 32)
                    .background(AppColor.categorySoft(category.colorToken), in: Circle())
                Text(category.name)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 9)
            .padding(.bottom, AppSpacing.sm)
            // 고른 칸만 바닥을 깔고 테두리를 두른다.
            .background(
                isSelected ? AppColor.surface : .clear,
                in: RoundedRectangle(cornerRadius: AppSpacing.md)
            )
            .overlay {
                RoundedRectangle(cornerRadius: AppSpacing.md)
                    .strokeBorder(isSelected ? tint : .clear, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.name)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    @Previewable @State var selection: UUID?

    let categories = [
        ExpenseCategory(name: "식비", symbolName: "fork.knife", colorToken: .orange),
        ExpenseCategory(name: "카페·간식", symbolName: "cup.and.saucer", colorToken: .brown),
        ExpenseCategory(name: "교통", symbolName: "bus", colorToken: .blue),
        ExpenseCategory(name: "생활", symbolName: "house", colorToken: .green)
    ]

    return CategoryPicker(categories: categories, selection: $selection)
        .padding(AppSpacing.screenMargin)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(AppColor.background)
}
