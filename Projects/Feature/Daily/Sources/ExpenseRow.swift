import SwiftUI
import DesignSystem
import Domain
import Shared

/// 목록 한 줄의 내용. 높이·배경·구분선은 `ReorderableList` 가 맡는다.
struct ExpenseRow: View {
    let expense: Expense
    let category: ExpenseCategory?

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            icon
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    // 접근성 글자 크기에서는 한 줄에 담기지 않아 두 줄까지 허용한다.
                    .lineLimit(typeSize.isAccessibilitySize ? 2 : 1)
                Text(category?.name ?? "미분류")
                    .font(AppFont.rowDetail)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: AppSpacing.sm)
            Text(AmountFormatter.full(expense.amount))
                .font(AppFont.amount)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var title: String {
        expense.memo.isEmpty ? (category?.name ?? "지출") : expense.memo
    }

    private var icon: some View {
        Image(systemName: category?.symbolName ?? "questionmark")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(tint, in: RoundedRectangle(cornerRadius: AppSpacing.sm))
    }

    private var tint: Color {
        category.map { AppColor.category($0.colorToken) } ?? AppColor.textSecondary
    }
}

#Preview {
    let food = ExpenseCategory(name: "식비", symbolName: "fork.knife", colorToken: .orange)

    return ExpenseRow(
        expense: Expense(amount: 12_800, memo: "점심 김치찌개", categoryID: food.id, date: CalendarDay.today()),
        category: food
    )
    .padding(.horizontal, AppSpacing.screenMargin)
    .frame(height: 68)
    .background(AppColor.surface)
}
