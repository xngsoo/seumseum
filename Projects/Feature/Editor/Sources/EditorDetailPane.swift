import SwiftUI
import DesignSystem
import Domain
import Shared

/// 날짜와 내용을 다루는 판.
/// 메모를 칠 때 시스템 키보드가 올라와도 이 판만 덮는다.
struct EditorDetailPane: View {
    let viewModel: ExpenseEditorViewModel
    @FocusState.Binding var isMemoFocused: Bool

    @State private var isCalendarPresented = false

    /// 줄 안쪽 높이. 날짜 줄의 화살표 버튼 크기에서 온 값이라 다른 줄도 여기에 맞춘다.
    private static let rowContentHeight: CGFloat = 28

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            dayRow
            memoRow
            splitRow
        }
        .padding(.horizontal, AppSpacing.sm)
    }

    // MARK: - 날짜

    private var dayRow: some View {
        HStack(spacing: 0) {
            Text("날짜")
                .font(AppFont.rowDetail)
                .foregroundStyle(AppColor.textSecondary)
            Spacer(minLength: AppSpacing.sm)
            stepButton(systemImage: "chevron.left", label: "이전 날짜") { viewModel.stepDay(-1) }
            dayLabelButton
            stepButton(systemImage: "chevron.right", label: "다음 날짜") { viewModel.stepDay(1) }
        }
        .frame(height: Self.rowContentHeight)
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
    }

    /// 하루씩 옮기기로는 먼 날짜를 고르기 힘들어 달력을 함께 둔다.
    private var dayLabelButton: some View {
        Button {
            isCalendarPresented = true
        } label: {
            Text(viewModel.dayLabel)
                .font(AppFont.rowDetail.weight(.medium))
                .foregroundStyle(AppColor.textPrimary)
                .frame(minWidth: 104)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("날짜 \(viewModel.dayLabel)")
        .accessibilityHint("두 번 누르면 달력에서 고릅니다")
        .popover(isPresented: $isCalendarPresented) { calendar }
    }

    /// 날짜를 고르면 곧바로 닫는다. 시스템 달력은 고른 뒤에도 그대로 떠 있어서
    /// 한 번 더 닫아야 하는데, 여기서는 고를 값이 하나뿐이라 그럴 이유가 없다.
    private var calendar: some View {
        DatePicker("", selection: dayBinding, displayedComponents: .date)
            .datePickerStyle(.graphical)
            .labelsHidden()
            .environment(\.calendar, CalendarDay.calendar)
            .environment(\.timeZone, CalendarDay.calendar.timeZone)
            .environment(\.locale, CalendarDay.locale)
            .tint(AppColor.accent)
            .padding(AppSpacing.md)
            .frame(width: 320, height: 360)
            .presentationCompactAdaptation(.popover)
    }

    // MARK: - 내용

    private var memoRow: some View {
        HStack(spacing: AppSpacing.md) {
            Text("내용")
                .font(AppFont.rowDetail)
                .foregroundStyle(AppColor.textSecondary)
            CaretEndTextField(
                "어디에 썼는지",
                text: memoBinding,
                font: AppFont.uiRowValue,
                alignment: .right
            )
            .focused($isMemoFocused)
        }
        // 날짜 줄과 같은 높이·글꼴로 맞춘다. 줄마다 크기가 다르면 카드가 들쭉날쭉해 보인다.
        .frame(height: Self.rowContentHeight)
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
    }

    /// 정액 품목 분리. 설정에서 켠 경우에만 보인다.
    /// 기능이 보류 중이라 `FeatureFlag.splitItem` 이 꺼져 있으면 아예 그리지 않는다.
    @ViewBuilder
    private var splitRow: some View {
        if FeatureFlag.splitItem, viewModel.showsSplitField, let item = viewModel.splitItem {
            VStack(alignment: .leading, spacing: 9) {
                Stepper(value: splitBinding, in: 0 ... 99) {
                    Text("\(item.name) \(viewModel.splitQuantity)\(item.unitLabel)")
                        .font(AppFont.rowDetail)
                        .foregroundStyle(AppColor.textSecondary)
                }
                if let preview = viewModel.splitPreview {
                    Text(preview)
                        .font(AppFont.caption)
                        .foregroundStyle(
                            viewModel.isSplitAmountValid ? AppColor.textMuted : AppColor.category(.red)
                        )
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 13)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
        }
    }

    private func stepButton(
        systemImage: String, label: String, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppColor.textFaint)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - 바인딩

    private var dayBinding: Binding<Date> {
        Binding(
            get: { viewModel.day },
            set: { picked in
                viewModel.setDay(picked)
                isCalendarPresented = false
            }
        )
    }

    private var memoBinding: Binding<String> {
        Binding(get: { viewModel.memo }, set: { viewModel.memo = $0 })
    }

    private var splitBinding: Binding<Int> {
        Binding(get: { viewModel.splitQuantity }, set: { viewModel.splitQuantity = $0 })
    }
}
