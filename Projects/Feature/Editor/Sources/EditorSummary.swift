import SwiftUI
import DesignSystem
import Domain

/// 지금까지 채운 내용을 한가운데 모아 보여 준다.
///
/// 입력 판은 화면 아래에 있고 위쪽은 결과를 비추는 자리다. 판을 옮겨 가며 넣은 값이
/// 여기 한 덩어리로 쌓여서, 저장을 누르기 전에 무엇이 비었는지 한눈에 보인다.
/// 각 줄은 그 값을 고치는 판으로 가는 입구이기도 하다.
struct EditorSummary: View {
    let category: ExpenseCategory?
    /// 자릿수를 끊은 금액. 아직 아무것도 안 넣었으면 빈 문자열.
    let amountText: String
    let memo: String
    let dayLabel: String
    /// 숫자 판이 열려 있는 동안에만 커서를 깜빡인다.
    let isEditingAmount: Bool
    let onSelectCategory: () -> Void
    let onSelectAmount: () -> Void
    let onSelectDetail: () -> Void

    @State private var isCaretVisible = true
    private let caretHeight: CGFloat = 26

    private var isAmountEmpty: Bool { amountText.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            icon
            categoryName
                .padding(.top, AppSpacing.md)
            memoText
                .padding(.top, 5)
            amount
                .padding(.top, AppSpacing.lg)
            // 어느 날짜에 들어가는지는 저장 전에 확인해야 한다. 상세 판을 열지 않고도 보이게 둔다.
            day
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.18), value: category)
    }

    // MARK: - 카테고리

    private var icon: some View {
        Button(action: onSelectCategory) {
            Group {
                if let category {
                    Image(systemName: category.symbolName)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(AppColor.category(category.colorToken))
                        .frame(width: 56, height: 56)
                        .background(AppColor.categorySoft(category.colorToken), in: Circle())
                } else {
                    // 아직 고르지 않았다는 것을 빈 자리로 알린다.
                    Circle()
                        .strokeBorder(
                            AppColor.dashedStroke,
                            style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                        )
                        .frame(width: 56, height: 56)
                }
            }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityHidden(true)
    }

    private var categoryName: some View {
        Button(action: onSelectCategory) {
            Text(category?.name ?? "카테고리")
                .font(AppFont.rowTitle)
                .foregroundStyle(category == nil ? AppColor.textDim : AppColor.textPrimary)
                .lineLimit(1)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.map { "카테고리 \($0.name)" } ?? "카테고리 없음")
        .accessibilityHint("두 번 누르면 카테고리를 고릅니다")
    }

    // MARK: - 내용

    private var memoText: some View {
        Button(action: onSelectDetail) {
            Text(memo.isEmpty ? "내용" : memo)
                .font(AppFont.rowDetail)
                .foregroundStyle(memo.isEmpty ? AppColor.textDim : AppColor.textSecondary)
                .lineLimit(1)
                .padding(.horizontal, AppSpacing.lg)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(memo.isEmpty ? "내용 없음" : "내용 \(memo)")
        .accessibilityHint("두 번 누르면 내용을 고칩니다")
    }

    // MARK: - 금액

    private var amount: some View {
        Button(action: onSelectAmount) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(isAmountEmpty ? "0" : amountText)
                    .font(AppFont.amountLarge)
                    .foregroundStyle(isAmountEmpty ? AppColor.textDim : AppColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                caret
                Text("원")
                    .font(AppFont.rowDetail)
                    .foregroundStyle(AppColor.textMuted)
            }
            .padding(.horizontal, AppSpacing.screenMargin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isAmountEmpty ? "금액 없음" : "금액 \(amountText)원")
        .accessibilityHint("두 번 누르면 금액을 고칩니다")
    }

    private var day: some View {
        Button(action: onSelectDetail) {
            Text(dayLabel)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textFaint)
                .lineLimit(1)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("날짜 \(dayLabel)")
        .accessibilityHint("두 번 누르면 날짜를 고칩니다")
    }

    /// 키패드로만 고치는 자리라 시스템 커서가 없다. 지금 입력받고 있다는 것을 막대로 알린다.
    @ViewBuilder
    private var caret: some View {
        if isEditingAmount {
            Rectangle()
                .fill(AppColor.accent)
                .frame(width: 2, height: caretHeight)
                .alignmentGuide(.firstTextBaseline) { $0.height * 0.86 }
                .opacity(isCaretVisible ? 1 : 0)
                // 켜지고 꺼지는 사이를 길게 둔다. 빠르면 읽는 데 방해가 된다.
                .animation(
                    .easeInOut(duration: 0.5).repeatForever().delay(1),
                    value: isCaretVisible
                )
                .onAppear { isCaretVisible = false }
                // 다른 판에 다녀오는 동안 되돌려 둔다. 꺼진 채로 두면 돌아왔을 때
                // 값이 그대로라 깜빡임이 시작되지 않아 커서가 보이지 않는다.
                .onDisappear { isCaretVisible = true }
        }
    }
}

#Preview {
    let food = ExpenseCategory(name: "식비", symbolName: "fork.knife", colorToken: .orange)

    return VStack(spacing: AppSpacing.xl * 2) {
        EditorSummary(
            category: nil, amountText: "", memo: "", dayLabel: "8월 13일 (목)", isEditingAmount: true,
            onSelectCategory: {}, onSelectAmount: {}, onSelectDetail: {}
        )
        EditorSummary(
            category: food, amountText: "12,800", memo: "점심 김치찌개",
            dayLabel: "8월 13일 (목)", isEditingAmount: false,
            onSelectCategory: {}, onSelectAmount: {}, onSelectDetail: {}
        )
    }
    .padding(.vertical, AppSpacing.xl)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(AppColor.background)
}
