import SwiftUI
import DesignSystem
import Domain
import Shared

struct ExpenseRow: View {
    let expense: Expense
    let category: ExpenseCategory?
    /// 재정렬 계산이 행 높이를 기준으로 하므로 높이는 목록이 정해서 내려준다.
    let height: CGFloat
    /// 마지막 행 아래에는 구분선을 두지 않는다.
    let showsSeparator: Bool

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            icon
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
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
        }
        .padding(.horizontal, AppSpacing.screenMargin)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(AppColor.surface)
        .overlay(alignment: .bottom) {
            if showsSeparator {
                Divider()
                    .overlay(AppColor.separator)
                    .padding(.leading, AppSpacing.screenMargin)
            }
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
    let cafe = ExpenseCategory(name: "카페", symbolName: "cup.and.saucer", colorToken: .brown)

    return VStack(spacing: 0) {
        ExpenseRow(
            expense: Expense(amount: 12_800, memo: "점심 김치찌개", categoryID: food.id, date: CalendarDay.today()),
            category: food,
            height: 68,
            showsSeparator: true
        )
        ExpenseRow(
            expense: Expense(amount: 4_500, categoryID: cafe.id, date: CalendarDay.today()),
            category: cafe,
            height: 68,
            showsSeparator: false
        )
    }
    .background(AppColor.background)
}
