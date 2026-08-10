import SwiftUI
import DesignSystem
import Domain
import Shared

public struct DailyView: View {
    @Environment(AppNavigation.self) private var navigation
    @State private var viewModel: DailyViewModel

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
            List {
                ForEach(viewModel.expenses) { expense in
                    ExpenseRow(expense: expense, category: viewModel.category(for: expense))
                        .listRowBackground(AppColor.surface)
                        .contentShape(Rectangle())
                        .onTapGesture { navigation.presentEditor(for: expense) }
                        .swipeActions(edge: .trailing) {
                            Button("삭제", role: .destructive) {
                                Task {
                                    await viewModel.delete(expense)
                                    navigation.dataDidChange()
                                }
                            }
                        }
                }
                .onMove { offsets, destination in
                    Task { await viewModel.move(from: offsets, to: destination) }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
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
