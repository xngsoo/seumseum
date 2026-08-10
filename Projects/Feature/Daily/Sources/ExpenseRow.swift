import SwiftUI
import DesignSystem
import Domain
import Shared

struct ExpenseRow: View {
    let expense: Expense
    let category: ExpenseCategory?

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            icon
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                Text(category?.name ?? "미분류")
                    .font(AppFont.rowDetail)
                    .foregroundStyle(AppColor.textSecondary)
            }
            Spacer(minLength: AppSpacing.sm)
            Text(AmountFormatter.full(expense.amount))
                .font(AppFont.amount)
                .foregroundStyle(AppColor.textPrimary)
        }
        .padding(.vertical, AppSpacing.xs)
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
