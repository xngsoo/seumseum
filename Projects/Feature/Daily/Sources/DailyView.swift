import SwiftUI
import DesignSystem
import Domain
import Shared

public struct DailyView: View {
    @Environment(AppNavigation.self) private var navigation
    @State private var viewModel: DailyViewModel
    /// 아이콘 36 + 위아래 여백. 글자 크기 설정을 따라간다.
    @ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = 68

    public init(
        expenseRepository: any ExpenseRepository,
        categoryRepository: any CategoryRepository
    ) {
        _viewModel = State(
            initialValue: DailyViewModel(
                expenseRepository: expenseRepository,
                categoryRepository: categoryRepository
            )
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            DailyHeader( 
                day: navigation.selectedDate,
                total: viewModel.total,
                onPrevious: { step(-1) },
                onNext: { step(1) }
            )
            Divider().overlay(AppColor.separator)
            listContent
        }
        .background(AppColor.background)
        .overlay(alignment: .bottom) { undoBar }
        .animation(.snappy, value: viewModel.pendingUndo)
        .task(id: LoadKey(day: navigation.selectedDate, version: navigation.dataVersion)) {
            await viewModel.load(day: navigation.selectedDate)
        }
    }

    @ViewBuilder
    private var listContent: some View {
        if viewModel.isEmpty {
            DailyEmptyView(onPrevious: { step(-1) }, onNext: { step(1) })
        } else {
            ReorderableList(
                viewModel.expenses,
                rowHeight: rowHeight,
                onSelect: { navigation.presentEditor(for: $0) },
                onDelete: { expense in
                    Task {
                        await viewModel.delete(expense)
                        navigation.dataDidChange()
                    }
                },
                onMove: { source, destination in
                    viewModel.moveLocally(from: source, to: destination)
                },
                onMoveEnded: {
                    Task { await viewModel.commitReorder() }
                }
            ) { expense in
                ExpenseRow(expense: expense, category: viewModel.category(for: expense))
            }
        }
    }

    @ViewBuilder
    private var undoBar: some View {
        if viewModel.pendingUndo != nil {
            UndoSnackbar {
                Task { await viewModel.undoDelete() }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.lg)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func step(_ days: Int) {
        navigation.selectedDate = CalendarDay.adding(days: days, to: navigation.selectedDate)
    }
    
    private struct LoadKey: Hashable {
        let day: Date
        let version: Int
    }
}
