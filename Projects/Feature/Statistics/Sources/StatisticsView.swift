import SwiftUI
import DesignSystem
import Domain
import Shared

public struct StatisticsView: View {
    @Environment(AppNavigation.self) private var navigation
    @State private var viewModel: StatisticsViewModel

    public init(
        expenseRepository: any ExpenseRepository,
        categoryRepository: any CategoryRepository,
        settingsRepository: any SettingsRepository
    ) {
        _viewModel = State(
            initialValue: StatisticsViewModel(
                expenseRepository: expenseRepository,
                categoryRepository: categoryRepository,
                settingsRepository: settingsRepository
            )
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            StatisticsHeader(
                periodText: viewModel.summary.periodText,
                total: viewModel.summary.total,
                onPrevious: { Task { await viewModel.goToPrevious() } },
                onNext: { Task { await viewModel.goToNext() } }
            )
            Divider().overlay(AppColor.separator)
            content
        }
        .background(AppColor.background)
        .contentShape(Rectangle())
        .gesture(
            PeriodSwipeGesture(
                onPrevious: { Task { await viewModel.goToPrevious() } },
                onNext: { Task { await viewModel.goToNext() } }
            ).gesture
        )
        .task(id: navigation.dataVersion) {
            await viewModel.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.summary.isEmpty {
            StatisticsEmptyView()
            Spacer(minLength: 0)
        } else {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    SummaryTiles(summary: viewModel.summary)
                    CategoryPieChart(shares: viewModel.summary.categoryShares)
                    WeeklyBarChart(weeks: viewModel.summary.weeklyTotals)
                }
                .padding(AppSpacing.md)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}
