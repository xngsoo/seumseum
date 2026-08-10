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
            DailyHeader(day: navigation.selectedDate, total: viewModel.total)
            Divider().overlay(AppColor.separator)
            listContent
        }
        .background(AppColor.background)
        .task(id: navigation.selectedDate) {
            await viewModel.load(day: navigation.selectedDate)
        }
    }

    @ViewBuilder
    private var listContent: some View {
        if viewModel.isEmpty {
            DailyEmptyView()
        } else {
            List(viewModel.expenses) { expense in
                ExpenseRow(expense: expense, category: viewModel.category(for: expense))
                    .listRowBackground(AppColor.surface)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}
