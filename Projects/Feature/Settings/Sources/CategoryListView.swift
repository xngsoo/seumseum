import SwiftUI
import DesignSystem
import Domain

struct CategoryListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppNavigation.self) private var navigation
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
        VStack(spacing: 0) {
            ScreenHeader("카테고리 관리", style: .subScreen, leading: .back("설정", { dismiss() }))
            list
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

    // MARK: - 목록

    private var list: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                capacityBar
                rows
                Text("카테고리는 최대 \(ExpenseCategory.maxCount)개까지 둘 수 있습니다. 추가 화면에 4열 × 3줄로 모두 보이게 하기 위해서입니다.")
                    .font(AppFont.caption)
                    .lineSpacing(3)
                    .foregroundStyle(AppColor.textFaint)
                    .padding(.horizontal, AppSpacing.screenMargin)
                    .padding(.top, 10)
            }
            .padding(.top, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl * 2)
        }
        .scrollIndicators(.hidden)
    }

    private var capacityBar: some View {
        HStack {
            Text(viewModel.countText)
                .font(AppFont.caption)
                .tracking(0.6)
                .foregroundStyle(AppColor.textFaint)
            Spacer(minLength: AppSpacing.sm)
            addButton
        }
        .padding(.horizontal, AppSpacing.screenMargin)
        .padding(.bottom, AppSpacing.md)
    }

    private var rows: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.categories.enumerated()), id: \.element.id) { index, category in
                CategoryRow(
                    category: category,
                    canMoveUp: viewModel.canMoveUp(category),
                    canMoveDown: viewModel.canMoveDown(category),
                    onEdit: { editorMode = .edit(category) },
                    onMoveUp: { Task { await viewModel.move(category, by: -1) } },
                    onMoveDown: { Task { await viewModel.move(category, by: 1) } },
                    onDelete: { Task { await viewModel.requestDelete(category) } }
                )
                if index < viewModel.categories.count - 1 {
                    Rectangle()
                        .fill(AppColor.separatorFaint)
                        .frame(height: 1)
                }
            }
        }
        .background(AppColor.surface)
        .overlay(alignment: .top) { hairline }
        .overlay(alignment: .bottom) { hairline }
    }

    private var hairline: some View {
        Rectangle()
            .fill(AppColor.separator)
            .frame(height: 1)
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
            Label("추가", systemImage: "plus")
                .font(AppFont.rowCaption)
                .foregroundStyle(viewModel.canAdd ? AppColor.accentInk : AppColor.textDim)
                .padding(.vertical, AppSpacing.xs)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canAdd)
        .accessibilityLabel("카테고리 추가")
    }
}
