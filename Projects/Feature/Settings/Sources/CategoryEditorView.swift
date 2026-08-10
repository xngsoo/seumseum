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
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    preview
                    nameSection
                    colorSection
                    symbolSection
                }
                .padding(AppSpacing.screenMargin)
            }
            .background(AppColor.background)
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { save() }.disabled(!viewModel.canSave)
                }
            }
            .alert("저장하지 못했습니다", isPresented: $viewModel.isErrorPresented) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .task { isNameFocused = true }
        }
    }

    private func save() {
        Task {
            if await viewModel.save() {
                onSaved()
                dismiss()
            }
        }
    }

    /// 지금 고른 색·아이콘·이름이 실제로 어떻게 보이는지 위에서 바로 확인한다.
    private var preview: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: viewModel.symbolName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(
                    AppColor.category(viewModel.colorToken),
                    in: RoundedRectangle(cornerRadius: AppSpacing.md)
                )
            Text(viewModel.name.isEmpty ? "이름 없음" : viewModel.name)
                .font(AppFont.screenTitle)
                .foregroundStyle(
                    viewModel.name.isEmpty ? AppColor.textSecondary : AppColor.textPrimary
                )
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
    }

    private var nameSection: some View {
        EditorSection(title: "이름") {
            TextField("예: 식비", text: $viewModel.name)
                .font(AppFont.rowTitle)
                .focused($isNameFocused)
                .submitLabel(.done)
                .onSubmit { isNameFocused = false }
                .padding(AppSpacing.md)
                .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppSpacing.sm))
        }
    }

    private var colorSection: some View {
        EditorSection(title: "색상") {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: 8),
                spacing: AppSpacing.sm
            ) {
                ForEach(ColorToken.allCases, id: \.self) { token in
                    Button {
                        viewModel.colorToken = token
                    } label: {
                        Circle()
                            .fill(AppColor.category(token))
                            .frame(height: 32)
                            .overlay {
                                if viewModel.colorToken == token {
                                    Circle().strokeBorder(AppColor.textPrimary, lineWidth: 2)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(token.rawValue))
                    .accessibilityAddTraits(viewModel.colorToken == token ? [.isSelected] : [])
                }
            }
        }
    }

    private var symbolSection: some View {
        EditorSection(title: "아이콘") {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: 6),
                spacing: AppSpacing.sm
            ) {
                ForEach(CategorySymbols.all, id: \.self) { symbol in
                    Button {
                        viewModel.symbolName = symbol
                    } label: {
                        Image(systemName: symbol)
                            .font(.system(size: 17))
                            .foregroundStyle(
                                viewModel.symbolName == symbol
                                    ? .white : AppColor.textPrimary
                            )
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                            .background(
                                viewModel.symbolName == symbol
                                    ? AppColor.category(viewModel.colorToken) : AppColor.surface,
                                in: RoundedRectangle(cornerRadius: AppSpacing.sm)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(symbol))
                    .accessibilityAddTraits(viewModel.symbolName == symbol ? [.isSelected] : [])
                }
            }
        }
    }
}

/// 섹션 제목 + 내용. Editor 모듈의 같은 이름 뷰와 별개다(모듈이 다르다).
struct EditorSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
