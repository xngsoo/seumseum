import SwiftUI
import DesignSystem
import Domain
import Shared

public struct StatisticsView: View {
    @Environment(AppNavigation.self) private var navigation
    @State private var viewModel: StatisticsViewModel

    /// 끄는 동안 내용이 따라 움직인 거리.
    @State private var dragOffset: CGFloat = 0
    /// 이번 끌기가 주기 넘기기인지 세로 스크롤인지.
    @State private var swipeDirection: PageSwipeGesture.Direction = .undecided

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
        ZStack {
            AppColor.background.ignoresSafeArea()
            periodPage
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.summary.period)
        .contentShape(Rectangle())
        .simultaneousGesture(swipe.gesture)
        .bottomFadeOverlay()
        .task(id: navigation.dataVersion) {
            await viewModel.load()
        }
        // 통계 탭을 다시 누르면 오늘이 든 주기로 돌아온다.
        .onChange(of: navigation.homeRequestCount) { _, _ in
            Task { await viewModel.goToCurrentPeriod() }
        }
    }

    /// 헤더는 자리를 지키고 기간만 바뀐다. 갈아 끼우는 것은 아래 내용뿐이다.
    private var periodPage: some View {
        ScrollView {
            VStack(spacing: 0) {
                StatisticsHeader(
                    periodText: viewModel.summary.periodText,
                    basisText: viewModel.basisText,
                    onPrevious: { step(-1) },
                    onNext: { step(1) }
                )
                periodBody
            }
            .padding(.horizontal, AppSpacing.screenMargin)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.scrollBottomInset)
        }
        .scrollIndicators(.hidden)
        // 주기를 넘기는 중에는 세로로 움직이지 않는다.
        .scrollDisabled(swipeDirection == .horizontal)
    }

    /// 겹쳐 놓고 흐리게 바꾼다. 세로로 쌓으면 바뀌는 동안 둘이 위아래로 늘어선다.
    private var periodBody: some View {
        ZStack(alignment: .top) {
            Group {
                if viewModel.summary.isEmpty {
                    StatisticsEmptyView()
                } else {
                    filledBody
                }
            }
            .id(viewModel.summary.period)
            .transition(.opacity)
        }
        .offset(x: dragOffset)
    }

    private var filledBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            CategoryPieChart(
                shares: viewModel.summary.categoryShares,
                total: viewModel.summary.total
            )
            .padding(.top, 30)

            SummaryTiles(summary: viewModel.summary)
                .padding(.top, 28)

            WeeklyBarChart(weeks: viewModel.summary.weeklyTotals)
                .padding(.top, 26)
        }
    }

    private var swipe: PageSwipeGesture {
        PageSwipeGesture(
            offset: $dragOffset,
            direction: $swipeDirection,
            onPrevious: { step(-1) },
            onNext: { step(1) }
        )
    }

    private func step(_ periods: Int) {
        Task {
            if periods < 0 {
                await viewModel.goToPrevious()
            } else {
                await viewModel.goToNext()
            }
        }
    }
}
