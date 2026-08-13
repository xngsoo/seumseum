import SwiftUI
import DesignSystem
import Domain
import Shared

/// 목록 한 줄의 내용. 높이·배경·구분선은 `ExpenseListView` 가 맡는다.
struct ExpenseRow: View {
    let expense: Expense
    let category: ExpenseCategory?

    var body: some View {
        HStack(spacing: 13) {
            icon
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                Text(category?.name ?? "미분류")
                    .font(AppFont.rowCaption)
                    .foregroundStyle(AppColor.textFaint)
                    .lineLimit(1)
            }
            Spacer(minLength: AppSpacing.sm)
            Text(AmountFormatter.grouped(expense.amount))
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
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(tint)
            .frame(width: 36, height: 36)
            .background(softTint, in: Circle())
    }

    private var tint: Color {
        category.map { AppColor.category($0.colorToken) } ?? AppColor.textMuted
    }

    private var softTint: Color {
        category.map { AppColor.categorySoft($0.colorToken) } ?? AppColor.highlight
    }
}

#Preview {
    let food = ExpenseCategory(name: "식비", symbolName: "fork.knife", colorToken: .orange)

    return ExpenseRow(
        expense: Expense(amount: 12_800, memo: "점심 김치찌개", categoryID: food.id, date: CalendarDay.today()),
        category: food
    )
    .padding(.horizontal, AppSpacing.screenMargin)
    .frame(height: 66)
    .background(AppColor.background)
}
