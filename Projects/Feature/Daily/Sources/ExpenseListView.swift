import SwiftUI
import DesignSystem
import Domain
import Shared

/// 탭 1의 지출 목록. 행을 눌러 수정 화면으로 간다.
///
/// 스크롤은 바깥 화면이 맡는다. 목록이 따로 스크롤되면 좌우 스와이프로 날짜를
/// 넘길 때 제스처가 겹친다.
///
/// 행은 `Button` 이 아니라 탭 제스처로 받는다. 버튼은 손가락이 제 영역을 벗어나야
/// 취소되는데, 행은 화면 폭을 다 쓰기 때문에 날짜를 넘기는 스와이프가 행 안에서
/// 끝나 버려 그대로 탭으로 처리된다. 탭 제스처는 손가락이 움직이면 성립하지 않는다.
struct ExpenseListView: View {
    let expenses: [Expense]
    let categories: [UUID: ExpenseCategory]
    /// 행의 최소 높이. 호출부에서 `@ScaledMetric` 으로 넘겨 글자 크기 설정을 따라간다.
    let rowHeight: CGFloat
    let onSelect: (Expense) -> Void

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(expenses) { expense in
                VStack(spacing: 0) {
                    ExpenseRow(expense: expense, category: categories[expense.categoryID])
                        .frame(maxWidth: .infinity, minHeight: rowHeight, alignment: .leading)
                    Rectangle()
                        .fill(AppColor.separatorFaint)
                        .frame(height: 1)
                }
                .contentShape(Rectangle())
                .onTapGesture { onSelect(expense) }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { onSelect(expense) }
            }
        }
    }
}

#Preview {
    let food = ExpenseCategory(name: "식비", symbolName: "fork.knife", colorToken: .orange)
    let cafe = ExpenseCategory(name: "카페", symbolName: "cup.and.saucer", colorToken: .brown)
    let day = CalendarDay.today()

    return ExpenseListView(
        expenses: [
            Expense(amount: 12_800, memo: "점심 김치찌개", categoryID: food.id, date: day, sortOrder: 0),
            Expense(amount: 4_500, memo: "아메리카노", categoryID: cafe.id, date: day, sortOrder: 1),
            Expense(amount: 32_000, memo: "장보기", categoryID: food.id, date: day, sortOrder: 2)
        ],
        categories: [food.id: food, cafe.id: cafe],
        rowHeight: 66,
        onSelect: { _ in }
    )
    .padding(.horizontal, AppSpacing.screenMargin)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(AppColor.background)
}
