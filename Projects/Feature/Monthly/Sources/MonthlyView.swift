import SwiftUI
import DesignSystem
import Domain
import Shared

public struct MonthlyView: View {
    @Environment(AppNavigation.self) private var navigation
    @State private var viewModel: MonthlyViewModel
    @State private var visibleMonth: Date = CalendarDay.startOfMonth(containing: CalendarDay.today())

    /// 끄는 동안 달력이 따라 움직인 거리.
    @State private var dragOffset: CGFloat = 0
    /// 이번 끌기가 달 넘기기인지 세로 스크롤인지.
    @State private var swipeDirection: PageSwipeGesture.Direction = .undecided

    public init(expenseRepository: any ExpenseRepository) {
        _viewModel = State(initialValue: MonthlyViewModel(expenseRepository: expenseRepository))
    }

    public var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            monthPage
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.loadedMonth)
        .contentShape(Rectangle())
        .simultaneousGesture(swipe.gesture)
        .safeAreaInset(edge: .bottom, spacing: 0) { pinnedSummary }
        .task(id: LoadKey(month: visibleMonth, version: navigation.dataVersion)) {
            await viewModel.load(month: visibleMonth)
        }
    }

    /// 헤더는 자리를 지키고 달 이름만 바뀐다. 갈아 끼우는 것은 달력과 합계뿐이다.
    private var monthPage: some View {
        ScrollView {
            VStack(spacing: 0) {
                MonthlyHeader(
                    month: viewModel.loadedMonth,
                    onPrevious: { step(-1) },
                    onNext: { step(1) }
                )
                monthBody
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.lg)
        }
        .scrollIndicators(.hidden)
        // 달을 넘기는 중에는 세로로 움직이지 않는다.
        .scrollDisabled(swipeDirection == .horizontal)
    }

    /// 달력이 6줄까지 늘어나도 요약은 같은 자리에 머문다.
    /// 달력이 짧은 달에는 그 사이가 비므로 요약이 그 자리를 채운다.
    private var pinnedSummary: some View {
        VStack(spacing: 0) {
            // 달력이 요약 뒤로 사라지도록 짧게 흐린다.
            AppColor.bottomFade
                .frame(height: AppSpacing.lg)
            MonthTotalCard(total: viewModel.monthTotal, comparison: viewModel.comparison)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.tabBarBottom + AppSpacing.tabBarHeight + AppSpacing.md)
                .background(AppColor.background)
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.loadedMonth)
    }

    /// 조회가 끝난 달을 기준으로 갈아 끼운다. 보고 있는 달로 바꾸면 아직 이전 달의
    /// 합계를 든 채로 새 달력이 들어온다.
    ///
    /// 겹쳐 놓고 흐리게 바꾼다. 세로로 쌓으면 바뀌는 동안 둘이 위아래로 늘어선다.
    private var monthBody: some View {
        ZStack(alignment: .top) {
            MonthGrid(
                month: viewModel.loadedMonth,
                today: CalendarDay.today(),
                selectedDay: navigation.selectedDate,
                total: viewModel.total(on:),
                onSelect: { navigation.showDaily($0) }
            )
            .padding(.top, AppSpacing.xl - AppSpacing.xs)
            .id(viewModel.loadedMonth)
            .transition(.opacity)
        }
        .offset(x: dragOffset)
    }

    private var swipe: PageSwipeGesture {
        PageSwipeGesture(
            offset: $dragOffset,
            direction: $swipeDirection,
            onPrevious: { step(-1) },
            onNext: { step(1) }
        )
    }

    private func step(_ months: Int) {
        visibleMonth = CalendarDay.startOfMonth(
            containing: CalendarDay.adding(months: months, to: visibleMonth)
        )
    }

    private struct LoadKey: Hashable {
        let month: Date
        let version: Int
    }
}
