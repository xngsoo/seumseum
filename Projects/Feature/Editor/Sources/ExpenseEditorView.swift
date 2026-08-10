import SwiftUI
import DesignSystem
import Domain
import Shared

public struct ExpenseEditorView: View {

    private enum Field: Hashable {
        case amount, memo
    }

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ExpenseEditorViewModel
    @FocusState private var focusedField: Field?

    private let onSaved: () -> Void

    public init(
        route: EditorRoute,
        expenseRepository: any ExpenseRepository,
        categoryRepository: any CategoryRepository,
        onSaved: @escaping () -> Void
    ) {
        self.onSaved = onSaved
        _viewModel = State(
            initialValue: ExpenseEditorViewModel(
                route: route,
                expenseRepository: expenseRepository,
                categoryRepository: categoryRepository
            )
        )
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    amountSection
                    categorySection
                    daySection
                    memoSection
                }
                .padding(AppSpacing.screenMargin)
                .frame(maxWidth: .infinity, alignment: .top)
                .background(dismissKeyboardLayer)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollBounceBehavior(.basedOnSize)
            .background(AppColor.background)
            .safeAreaInset(edge: .bottom) { saveButton }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
            .task {
                await viewModel.load()
                focusedField = .amount
            }
        }
    }
    
    private var saveButton: some View {
        Button(action: save) {
            Text(viewModel.isEditing ? "수정 완료" : "저장")
                .font(AppFont.rowTitle)
                .foregroundStyle(viewModel.canSave ? .white : AppColor.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(
                    viewModel.canSave ? AppColor.accent : AppColor.separator
                )
        }
        .disabled(!viewModel.canSave)
        .background(AppColor.surface)
    }

    /// 콘텐츠 뒤에 깔리는 투명 레이어. 버튼·필드가 아닌 빈 곳의 탭만 받는다.
    private var dismissKeyboardLayer: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture { focusedField = nil }
    }

    private func save() {
        Task {
            if await viewModel.save() {
                onSaved()
                dismiss()
            }
        }
    }

    private var amountSection: some View {
        EditorSection(title: "금액") {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                TextField("0", text: amountBinding)
                    .font(AppFont.amountLarge)
                    .foregroundStyle(AppColor.textPrimary)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .amount)
                    .fixedSize()
                Text("원")
                    .font(AppFont.amountLarge)
                    .foregroundStyle(AppColor.textPrimary)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .onTapGesture { focusedField = .amount }
        }
    }

    /// 편집 대상은 서식이 적용된 숫자뿐이다. 단위는 필드 밖에 있어 지워지지 않는다.
    private var amountBinding: Binding<String> {
        Binding(
            get: { viewModel.groupedAmount },
            set: { viewModel.updateAmount($0) }
        )
    }

    private var categorySection: some View {
        EditorSection(title: "카테고리") {
            CategoryPicker(
                categories: viewModel.categories,
                selection: $viewModel.categoryID
            )
        }
    }

    private var daySection: some View {
        EditorSection(title: "날짜") {
            DatePicker(
                "",
                selection: $viewModel.day,
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .environment(\.calendar, CalendarDay.calendar)
            .environment(\.timeZone, CalendarDay.calendar.timeZone)
            .environment(\.locale, CalendarDay.locale)
        }
    }

    private var memoSection: some View {
        EditorSection(title: "내용") {
            TextField("어디에 썼나요?", text: $viewModel.memo)
                .font(AppFont.rowTitle)
                .focused($focusedField, equals: .memo)
                .submitLabel(.done)
                .onSubmit { focusedField = nil }
                .padding(AppSpacing.md)
                .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppSpacing.sm))
        }
    }
}
