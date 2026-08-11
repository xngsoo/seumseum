import SwiftUI
import DesignSystem
import Domain
import Shared

struct CategoryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CategoryEditorViewModel
    @FocusState private var isNameFocused: Bool

    private let onSaved: () -> Void

    init(
        mode: CategoryEditorViewModel.Mode,
        categoryRepository: any CategoryRepository,
        onSaved: @escaping () -> Void
    ) {
        self.onSaved = onSaved
        _viewModel = State(
            initialValue: CategoryEditorViewModel(mode: mode, categoryRepository: categoryRepository)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(viewModel.title, style: .sheet, leading: .close { dismiss() })

            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    preview
                    nameSection
                    colorSection
                    symbolSection
                }
                .padding(.horizontal, AppSpacing.screenMargin)
                .padding(.vertical, AppSpacing.lg)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .background(AppColor.background)
        .safeAreaInset(edge: .bottom) { saveButton }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .dimmedAlert(
            isPresented: $viewModel.isErrorPresented,
            title: "저장하지 못했습니다",
            message: viewModel.errorMessage ?? "",
            confirmTitle: "확인",
            cancelTitle: nil
        )
        .task {
            // 수정할 때는 이미 이름이 있으니 키보드를 띄우지 않는다. 새로 만들 때만 바로 입력받는다.
            guard !viewModel.isEditing else { return }
            isNameFocused = true
        }
    }

    /// 지금 고른 색·아이콘·이름이 실제로 어떻게 보이는지 위에서 바로 확인한다.
    private var preview: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: viewModel.symbolName)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(
                    AppColor.category(viewModel.colorToken),
                    in: RoundedRectangle(cornerRadius: AppSpacing.lg)
                )
            Text(viewModel.name.isEmpty ? "이름 없음" : viewModel.name)
                .font(AppFont.screenTitle)
                .foregroundStyle(
                    viewModel.name.isEmpty ? AppColor.textSecondary : AppColor.textPrimary
                )
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
    }

    private var nameSection: some View {
        LabeledSection("이름") {
            TextField("예: 식비", text: $viewModel.name)
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textPrimary)
                .focused($isNameFocused)
                .submitLabel(.done)
                .onSubmit { isNameFocused = false }
                .padding(.horizontal, AppSpacing.lg)
                .frame(height: 52)
                .background(
                    AppColor.surface,
                    in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                )
        }
    }

    private var colorSection: some View {
        LabeledSection("색상") {
            LazyVGrid(
                // 12색이 6열 두 줄로 떨어진다.
                columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.md), count: 6),
                spacing: AppSpacing.md
            ) {
                ForEach(ColorToken.allCases, id: \.self) { token in
                    Button {
                        viewModel.colorToken = token
                    } label: {
                        Circle()
                            .fill(AppColor.category(token))
                            .frame(height: 30)
                            .overlay {
                                if viewModel.colorToken == token {
                                    Circle()
                                        .strokeBorder(AppColor.textPrimary, lineWidth: 2)
                                        .padding(-4)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(token.rawValue))
                    .accessibilityAddTraits(viewModel.colorToken == token ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.lg)
            .frame(maxWidth: .infinity)
            .background(
                AppColor.surface,
                in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
            )
        }
    }

    private var symbolSection: some View {
        LabeledSection("아이콘") {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.xs), count: 6),
                spacing: AppSpacing.xs
            ) {
                ForEach(CategorySymbols.all, id: \.self) { symbol in
                    Button {
                        viewModel.symbolName = symbol
                    } label: {
                        Image(systemName: symbol)
                            .font(.system(size: 17))
                            .foregroundStyle(
                                viewModel.symbolName == symbol ? .white : AppColor.textPrimary
                            )
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                            // 카드 안이므로 고르지 않은 칸은 배경을 비운다.
                            .background(
                                viewModel.symbolName == symbol
                                    ? AppColor.category(viewModel.colorToken) : .clear,
                                in: RoundedRectangle(cornerRadius: AppSpacing.sm)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(symbol))
                    .accessibilityAddTraits(viewModel.symbolName == symbol ? [.isSelected] : [])
                }
            }
            .padding(AppSpacing.sm)
            .background(
                AppColor.surface,
                in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
            )
        }
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
        .padding(.horizontal, AppSpacing.screenMargin)
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.xs)
        .background(AppColor.background)
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
