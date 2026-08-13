import SwiftUI
import DesignSystem
import Domain
import Shared

public struct ExpenseEditorView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ExpenseEditorViewModel
    /// 아래 절반에 열려 있는 판. 들어오면 금액부터 넣는다.
    @State private var pane: EditorPane = .amount
    @FocusState private var isMemoFocused: Bool
    @State private var isDeleteConfirmPresented = false

    /// 판이 바뀌어도 화면이 흔들리지 않도록 높이를 고정한다. 키패드가 가장 크다.
    private let paneHeight: CGFloat = 242

    private let onSaved: () -> Void
    private let onDeleted: (Expense, Int) -> Void

    public init(
        route: EditorRoute,
        expenseRepository: any ExpenseRepository,
        categoryRepository: any CategoryRepository,
        settingsRepository: any SettingsRepository,
        onSaved: @escaping () -> Void,
        onDeleted: @escaping (Expense, Int) -> Void
    ) {
        self.onSaved = onSaved
        self.onDeleted = onDeleted
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
            header
            // 내용을 칠 때는 요약을 접는다. 키보드가 올라오면 남은 높이가 모자라
            // 위쪽이 눌리면서 글자와 여백이 어긋난다. 판만 키보드 위로 올린다.
            if !isMemoFocused {
                Spacer(minLength: AppSpacing.md)
                summary
                deleteButton
            }
            Spacer(minLength: AppSpacing.md)
            paneSection
        }
        .animation(.easeInOut(duration: 0.22), value: isMemoFocused)
        .background(AppColor.background)
        .dimmedAlert(
            isPresented: $isDeleteConfirmPresented,
            title: "이 지출을 삭제할까요?",
            message: "목록으로 돌아가면 잠시 동안 되돌릴 수 있습니다.",
            confirmTitle: "삭제",
            isDestructive: true,
            onConfirm: delete
        )
        .task { await viewModel.load() }
    }

    // MARK: - 머리

    /// 저장은 오른쪽 위에 둔다. 아래는 입력 판이 다 차지해서 버튼을 둘 자리가 없다.
    private var header: some View {
        ScreenHeader(viewModel.title, style: .sheet, leading: .cancel { dismiss() }) {
            Button("저장", action: save)
                .font(AppFont.rowDetail.weight(.semibold))
                .foregroundStyle(viewModel.canSave ? AppColor.accent : AppColor.textDim)
                .buttonStyle(.plain)
                .disabled(!viewModel.canSave)
                .frame(width: 56, alignment: .trailing)
        }
    }

    /// 지우기는 요약 아래에 홀로 둔다. 저장 옆에 붙여 두면 손이 미끄러지기 쉽고,
    /// 지우려는 대상이 바로 위에 보이는 자리가 무엇을 지우는지도 분명하다.
    @ViewBuilder
    private var deleteButton: some View {
        if viewModel.isEditing {
            Button {
                isDeleteConfirmPresented = true
            } label: {
                Label("삭제", systemImage: "trash")
                    .font(AppFont.rowCaption)
                    .foregroundStyle(AppColor.category(.red))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(AppColor.categorySoft(.red), in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isSaving)
            .padding(.top, 28)
        }
    }

    // MARK: - 금액과 요약

    private var summary: some View {
        EditorSummary(
            category: viewModel.selectedCategory,
            amountText: viewModel.groupedAmount,
            memo: viewModel.memo,
            dayLabel: viewModel.dayLabel,
            isEditingAmount: pane == .amount,
            onSelectCategory: { paneBinding.wrappedValue = .category },
            onSelectAmount: { paneBinding.wrappedValue = .amount },
            onSelectDetail: { paneBinding.wrappedValue = .detail }
        )
        .padding(.horizontal, AppSpacing.screenMargin)
    }

    // MARK: - 입력 판

    private var paneSection: some View {
        VStack(spacing: 0) {
            SegmentedControl(EditorPane.allCases, selection: paneBinding) { $0.title }
                .padding(.horizontal, AppSpacing.screenMargin)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, 10)

            pane(for: pane)
                // 판마다 내용 높이가 달라도 같은 자리를 차지해야 요약이 흔들리지 않는다.
                .frame(
                    maxWidth: .infinity,
                    minHeight: paneHeight,
                    maxHeight: paneHeight,
                    alignment: .top
                )
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, 26)
        }
        .background(AppColor.surfaceSunken)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColor.separator)
                .frame(height: 1)
        }
        .animation(.easeInOut(duration: 0.18), value: pane)
    }

    @ViewBuilder
    private func pane(for pane: EditorPane) -> some View {
        switch pane {
        case .amount:
            AmountKeypad(
                onDigits: { viewModel.appendDigits($0) },
                onDelete: { viewModel.deleteLastDigit() },
                onClear: { viewModel.clearAmount() }
            )
            .transition(.opacity)
        case .category:
            CategoryPicker(
                categories: viewModel.categories,
                selection: $viewModel.categoryID
            )
            .padding(.horizontal, AppSpacing.sm)
            .transition(.opacity)
        case .detail:
            EditorDetailPane(viewModel: viewModel, isMemoFocused: $isMemoFocused)
                .transition(.opacity)
        }
    }

    // MARK: - 바인딩

    /// 판을 옮길 때 메모 입력에서 손을 뗀다. 키보드가 남으면 다음 판을 덮는다.
    private var paneBinding: Binding<EditorPane> {
        Binding(
            get: { pane },
            set: { next in
                if next != .detail { isMemoFocused = false }
                pane = next
            }
        )
    }

    // MARK: - 동작

    private func save() {
        Task {
            if await viewModel.save() {
                onSaved()
                dismiss()
            }
        }
    }

    private func delete() {
        guard let expense = viewModel.editingExpense else { return }
        Task {
            if let index = await viewModel.delete() {
                onDeleted(expense, index)
                dismiss()
            }
        }
    }
}
