import SwiftUI
import DesignSystem
import Domain

struct CategoryListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CategoryListViewModel
    @State private var editorMode: CategoryEditorViewModel.Mode?
    /// 아이콘 32 + 위아래 여백. 글자 크기 설정을 따라간다.
    @ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = 56

    private let categoryRepository: any CategoryRepository

    init(categoryRepository: any CategoryRepository) {
        self.categoryRepository = categoryRepository
        _viewModel = State(
            initialValue: CategoryListViewModel(categoryRepository: categoryRepository)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader("카테고리 관리", style: .subScreen, leading: .back { dismiss() }) {
                addButton
            }
            Divider().overlay(AppColor.separator)

            ReorderableList(
                viewModel.categories,
                rowHeight: rowHeight,
                onSelect: { editorMode = .edit($0) },
                onDelete: { category in
                    Task { await viewModel.delete(category) }
                },
                onMove: { source, destination in
                    viewModel.moveLocally(from: source, to: destination)
                },
                onMoveEnded: {
                    Task { await viewModel.commitReorder() }
                }
            ) { category in
                CategoryRow(category: category)
            } footer: {
                Text("\(viewModel.capacityText) · 길게 눌러 순서를 바꿉니다")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppSpacing.screenMargin)
                    .padding(.vertical, AppSpacing.md)
            }
        }
        .background(AppColor.background)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $editorMode) { mode in
            CategoryEditorView(
                mode: mode,
                categoryRepository: categoryRepository,
                onSaved: { Task { await viewModel.load() } }
            )
        }
        .alert("처리하지 못했습니다", isPresented: $viewModel.isErrorPresented) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task { await viewModel.load() }
    }

    private var addButton: some View {
        Button {
            editorMode = .create(nextIndex: viewModel.categories.count)
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(viewModel.canAdd ? AppColor.accent : AppColor.separator)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canAdd)
        .accessibilityLabel("카테고리 추가")
    }
}
