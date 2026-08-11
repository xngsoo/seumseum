import SwiftUI
import DesignSystem
import Domain
import Shared

public struct ExpenseEditorView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ExpenseEditorViewModel

    private let onSaved: () -> Void

    public init(
        route: EditorRoute,
        expenseRepository: any ExpenseRepository,
        categoryRepository: any CategoryRepository,
        settingsRepository: any SettingsRepository,
        onSaved: @escaping () -> Void
    ) {
        self.onSaved = onSaved
        _viewModel = State(
            initialValue: ExpenseEditorViewModel(
                route: route,
                expenseRepository: expenseRepository,
                categoryRepository: categoryRepository,
                settingsRepository: settingsRepository
            )
        )
    }

    public var body: some View {
        NavigationStack {
            // 키패드와 저장 버튼은 항상 고정이고, 넘치는 경우에만 위쪽이 스크롤된다.
            // 카테고리 12개 + 작은 화면 조합에서만 실제로 스크롤이 생긴다.
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    amountRow
                    CategoryPicker(
                        categories: viewModel.categories,
                        selection: $viewModel.categoryID
                    )
                    splitSection
                    detailRows
                }
                .padding(.horizontal, AppSpacing.screenMargin)
                .padding(.vertical, AppSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
            .background(AppColor.background)
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) { bottomBar }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .task { await viewModel.load() }
        }
    }

    // MARK: - 상단

    private var amountRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(viewModel.groupedAmount.isEmpty ? "0" : viewModel.groupedAmount)
                .font(AppFont.amountLarge)
                .foregroundStyle(
                    viewModel.groupedAmount.isEmpty ? AppColor.textSecondary : AppColor.textPrimary
                )
            Text("원")
                .font(AppFont.amountLarge)
                .foregroundStyle(AppColor.textPrimary)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("금액 \(viewModel.formattedAmount)")
    }

    /// 정액 품목 분리. 설정에서 켠 경우에만 보인다.
    /// 기능이 보류 중이라 `FeatureFlag.splitItem` 이 꺼져 있으면 아예 그리지 않는다.
    @ViewBuilder
    private var splitSection: some View {
        if FeatureFlag.splitItem, viewModel.showsSplitField, let item = viewModel.splitItem {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Stepper(value: $viewModel.splitQuantity, in: 0 ... 99) {
                    HStack {
                        Text("\(item.name) 분리")
                            .font(AppFont.rowDetail)
                            .foregroundStyle(AppColor.textSecondary)
                        Spacer()
                        Text("\(viewModel.splitQuantity)\(item.unitLabel)")
                            .font(AppFont.amount)
                            .foregroundStyle(AppColor.textPrimary)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppSpacing.sm))

                if let preview = viewModel.splitPreview {
                    Text(preview)
                        .font(AppFont.caption)
                        .foregroundStyle(
                            viewModel.isSplitAmountValid ? AppColor.accent : AppColor.category(.red)
                        )
                }
            }
        }
    }

    /// 날짜와 내용은 한 줄씩. 값이 항상 보이므로 저장 직전에 확인할 수 있다.
    private var detailRows: some View {
        VStack(spacing: 0) {
            HStack {
                Text("날짜")
                    .font(AppFont.rowDetail)
                    .foregroundStyle(AppColor.textSecondary)
                Spacer()
                DatePicker("", selection: $viewModel.day, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .environment(\.calendar, CalendarDay.calendar)
                    .environment(\.timeZone, CalendarDay.calendar.timeZone)
                    .environment(\.locale, CalendarDay.locale)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)

            Divider().overlay(AppColor.separator)

            HStack {
                Text("내용")
                    .font(AppFont.rowDetail)
                    .foregroundStyle(AppColor.textSecondary)
                CaretEndTextField("어디에 썼나요?", text: $viewModel.memo, alignment: .right)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
        }
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppSpacing.sm))
    }

    // MARK: - 하단

    /// 메모를 입력할 때는 시스템 키보드가 올라오므로 키패드를 감춘다.
    /// 저장 버튼은 두 경우 모두 남아 위치가 흔들리지 않는다.
    private var bottomBar: some View {
        VStack(spacing: AppSpacing.sm) {
            AmountKeypad(
                onDigits: { viewModel.appendDigits($0) },
                onDelete: { viewModel.deleteLastDigit() },
                onClear: { viewModel.clearAmount() }
            )
            saveButton
        }
        .padding(.horizontal, AppSpacing.screenMargin)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColor.background)
    }

    private var saveButton: some View {
        Button(action: save) {
            Text(viewModel.isEditing ? "수정 완료" : "저장")
                .font(AppFont.rowTitle)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(
                    viewModel.canSave ? AppColor.accent : AppColor.separator,
                    in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                )
        }
        .disabled(!viewModel.canSave)
    }

    private func save() {
        Task {
            if await viewModel.save() {
                onSaved()
                dismiss()
            }
        }
    }
}
