import SwiftUI
import DesignSystem
import Domain

struct CategoryListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppNavigation.self) private var navigation
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
                    Task { await viewModel.requestDelete(category) }
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
        // 삭제 확인과 오류 안내를 한 창으로 모은다. fullScreenCover 는 한 뷰에 하나만 동작한다.
        .dimmedAlert(
            isPresented: alertBinding,
            title: alertTitle,
            message: alertMessage,
            confirmTitle: activeAlert == .deletion ? "삭제" : "확인",
            isDestructive: activeAlert == .deletion,
            cancelTitle: activeAlert == .deletion ? "취소" : nil
        ) {
            guard activeAlert == .deletion else { return }
            // 창이 닫히면서 취소가 뒤따르므로, 대상은 여기서 먼저 꺼내 둔다.
            guard let target = viewModel.takePendingDeletion() else { return }
            Task {
                await viewModel.delete(target)
                navigation.dataDidChange()
            }
        }
        .sheet(item: $editorMode) { mode in
            CategoryEditorView(
                mode: mode,
                categoryRepository: categoryRepository,
                onSaved: { Task { await viewModel.load() } }
            )
        }
        .task { await viewModel.load() }
    }

    // MARK: - 안내 창

    private enum ActiveAlert {
        case deletion
        case error
    }

    private var activeAlert: ActiveAlert? {
        if viewModel.pendingDeletion != nil { return .deletion }
        if viewModel.isErrorPresented { return .error }
        return nil
    }

    private var alertTitle: String {
        switch activeAlert {
        case .deletion: viewModel.deletionTitle
        case .error: "처리하지 못했습니다"
        case nil: ""
        }
    }

    private var alertMessage: String {
        switch activeAlert {
        case .deletion: viewModel.deletionMessage
        case .error: viewModel.errorMessage ?? ""
        case nil: ""
        }
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { activeAlert != nil },
            set: { isPresented in
                guard !isPresented else { return }
                viewModel.cancelDeletion()
                viewModel.isErrorPresented = false
            }
        )
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
