import SwiftUI
import DesignSystem
import Domain
import Shared

public struct MonthlyView: View {
    @Environment(AppNavigation.self) private var navigation
    @State private var viewModel: MonthlyViewModel
    @State private var visibleMonth: Date = CalendarDay.startOfMonth(containing: CalendarDay.today())

    public init(expenseRepository: any ExpenseRepository) {
        _viewModel = State(initialValue: MonthlyViewModel(expenseRepository: expenseRepository))
    }

    public var body: some View {
        VStack(spacing: 0) {
            MonthlyHeader(
                month: visibleMonth,
                total: viewModel.monthTotal,
                onPrevious: { step(-1) },
                onNext: { step(1) }
            )
            Divider().overlay(AppColor.separator)
            MonthGrid(
                month: visibleMonth,
                today: CalendarDay.today(),
                total: viewModel.total(on:),
                onSelect: { navigation.showDaily($0) }
            )
            .padding(.horizontal, AppSpacing.sm)
            .padding(.top, AppSpacing.sm)
            Spacer(minLength: 0)
        }
        .background(AppColor.background)
        .contentShape(Rectangle())
        .gesture(MonthSwipeGesture(onPrevious: { step(-1) }, onNext: { step(1) }).gesture)
        .task(id: LoadKey(month: visibleMonth, version: navigation.dataVersion)) {
            await viewModel.load(month: visibleMonth)
        }
    }

    private struct LoadKey: Hashable {
        let month: Date
        let version: Int
    }

    private func step(_ months: Int) {
        visibleMonth = CalendarDay.startOfMonth(
            containing: CalendarDay.adding(months: months, to: visibleMonth)
        )
    }
}
