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
        VStack(spacing: 0) {
            ScreenHeader(viewModel.title, style: .sheet, leading: .close { dismiss() })

            // 키패드와 저장 버튼은 항상 고정이고, 넘치는 경우에만 위쪽이 스크롤된다.
            // 카테고리 12개 + 작은 화면 조합에서만 실제로 스크롤이 생긴다.
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    amountCard
                    categorySection
                    splitSection
                    detailCard
                }
                .padding(.horizontal, AppSpacing.screenMargin)
                .padding(.vertical, AppSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .background(AppColor.background)
        .safeAreaInset(edge: .bottom) { bottomBar }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .task { await viewModel.load() }
    }

    // MARK: - 금액

    private var amountCard: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(viewModel.groupedAmount.isEmpty ? "0" : viewModel.groupedAmount)
                .font(AppFont.amountLarge)
                .foregroundStyle(
                    viewModel.groupedAmount.isEmpty ? AppColor.textSecondary : AppColor.textPrimary
                )
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("원")
                .font(AppFont.amountLarge)
                .foregroundStyle(AppColor.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("금액 \(viewModel.formattedAmount)")
    }

    // MARK: - 카테고리

    /// 격자를 카드 하나에 담고 고르지 않은 칸은 배경을 비운다.
    /// 칸마다 배경을 깔면 카드 안에 카드가 겹친 것처럼 보인다.
    private var categorySection: some View {
        LabeledSection("카테고리") {
            CategoryPicker(
                categories: viewModel.categories,
                selection: $viewModel.categoryID
            )
            .padding(AppSpacing.md)
            .background(
                AppColor.surface,
                in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
            )
        }
    }

    /// 정액 품목 분리. 설정에서 켠 경우에만 보인다.
    /// 기능이 보류 중이라 `FeatureFlag.splitItem` 이 꺼져 있으면 아예 그리지 않는다.
    @ViewBuilder
    private var splitSection: some View {
        if FeatureFlag.splitItem, viewModel.showsSplitField, let item = viewModel.splitItem {
            LabeledSection("\(item.name) 분리") {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Stepper(value: $viewModel.splitQuantity, in: 0 ... 99) {
                        Text("\(viewModel.splitQuantity)\(item.unitLabel)")
                            .font(AppFont.amount)
                            .foregroundStyle(AppColor.textPrimary)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        AppColor.surface,
                        in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                    )

                    if let preview = viewModel.splitPreview {
                        Text(preview)
                            .font(AppFont.caption)
                            .foregroundStyle(
                                viewModel.isSplitAmountValid
                                    ? AppColor.accent : AppColor.category(.red)
                            )
                            .padding(.horizontal, AppSpacing.xs)
                    }
                }
            }
        }
    }

    // MARK: - 날짜와 내용

    /// 값이 항상 보이므로 저장 직전에 확인할 수 있다.
    private var detailCard: some View {
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
            .padding(.horizontal, AppSpacing.lg)
            .frame(height: 52)

            Divider()
                .overlay(AppColor.separator)
                .padding(.leading, AppSpacing.lg)

            HStack(spacing: AppSpacing.md) {
                Text("내용")
                    .font(AppFont.rowDetail)
                    .foregroundStyle(AppColor.textSecondary)
                CaretEndTextField("어디에 썼나요?", text: $viewModel.memo, alignment: .right)
            }
            .padding(.horizontal, AppSpacing.lg)
            .frame(height: 52)
        }
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
    }

    // MARK: - 하단

    /// 메모를 입력할 때는 시스템 키보드가 키패드를 가린다.
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
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.xs)
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
