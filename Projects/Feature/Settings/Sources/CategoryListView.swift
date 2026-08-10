import SwiftUI
import DesignSystem
import Domain

struct CategoryListView: View {
    @State private var viewModel: CategoryListViewModel
    @State private var editorMode: CategoryEditorViewModel.Mode?

    private let categoryRepository: any CategoryRepository

    init(categoryRepository: any CategoryRepository) {
        self.categoryRepository = categoryRepository
        _viewModel = State(
            initialValue: CategoryListViewModel(categoryRepository: categoryRepository)
        )
    }

    var body: some View {
        List {
            Section {
                ForEach(viewModel.categories) { category in
                    CategoryRow(category: category)
                        .onTapGesture { editorMode = .edit(category) }
                        .swipeActions(edge: .trailing) {
                            Button("삭제", role: .destructive) {
                                Task { await viewModel.delete(category) }
                            }
                        }
                }
                .onMove { offsets, destination in
                    Task { await viewModel.move(from: offsets, to: destination) }
                }
            } footer: {
                Text("\(viewModel.capacityText) · 길게 눌러 순서를 바꿉니다")
                    .font(AppFont.caption)
            }
            .listRowBackground(AppColor.surface)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppColor.background)
        .navigationTitle("카테고리 관리")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editorMode = .create(nextIndex: viewModel.categories.count)
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(!viewModel.canAdd)
                .accessibilityLabel("카테고리 추가")
            }
        }
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
}
