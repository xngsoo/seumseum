import SwiftUI
import DesignSystem
import Domain
import Shared

public struct DailyView: View {
    @Environment(AppNavigation.self) private var navigation
    @State private var viewModel: DailyViewModel
    /// 아이콘 36 + 위아래 여백. 글자 크기 설정을 따라간다.
    @ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = 66

    /// 끄는 동안 목록이 따라 움직인 거리.
    @State private var dragOffset: CGFloat = 0
    /// 이번 끌기가 날짜 넘기기인지 목록 스크롤인지.
    @State private var swipeDirection: PageSwipeGesture.Direction = .undecided

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
        ZStack {
            AppColor.background.ignoresSafeArea()
            dayPage
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.loadedDay)
        .contentShape(Rectangle())
        .simultaneousGesture(swipe.gesture)
        .bottomFadeOverlay()
        .overlay(alignment: .bottom) { undoBar }
        .animation(.snappy, value: viewModel.pendingUndo)
        .task(id: LoadKey(day: navigation.selectedDate, version: navigation.dataVersion)) {
            await viewModel.load(day: navigation.selectedDate)
            receiveDeletionFromEditor()
        }
    }

    // MARK: - 하루

    /// 헤더는 자리를 지키고 값만 바뀐다. 갈아 끼우는 것은 목록뿐이다.
    private var dayPage: some View {
        ScrollView {
            VStack(spacing: 0) {
                DailyHeader(
                    day: viewModel.loadedDay,
                    total: viewModel.total,
                    isToday: viewModel.loadedDay == CalendarDay.today(),
                    onPrevious: { step(-1) },
                    onNext: { step(1) },
                    onToday: { goToday() }
                )
                dayBody
            }
            .padding(.horizontal, AppSpacing.screenMargin)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.scrollBottomInset)
        }
        .scrollIndicators(.hidden)
        // 날짜를 넘기는 중에는 세로로 움직이지 않는다.
        .scrollDisabled(swipeDirection == .horizontal)
    }

    /// 조회가 끝난 날짜를 기준으로 갈아 끼운다. 보고 있는 날짜로 바꾸면
    /// 아직 이전 날짜의 내역을 든 채로 새 목록이 들어온다.
    ///
    /// 겹쳐 놓고 흐리게 바꾼다. 세로로 쌓으면 바뀌는 동안 둘이 위아래로 늘어선다.
    private var dayBody: some View {
        ZStack(alignment: .top) {
            Group {
                if viewModel.isEmpty {
                    DailyEmptyView(onAdd: { navigation.presentCreateEditor() })
                } else {
                    ExpenseListView(
                        expenses: viewModel.expenses,
                        categories: viewModel.categories,
                        rowHeight: rowHeight,
                        onSelect: { navigation.presentEditor(for: $0) }
                    )
                }
            }
            .id(viewModel.loadedDay)
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

    // MARK: - 삭제 취소

    /// 수정 화면이 지운 기록을 넘겨받는다. 삭제는 이미 끝났고 되돌릴 시간만 연다.
    private func receiveDeletionFromEditor() {
        guard let deleted = navigation.lastDeleted else { return }
        navigation.clearLastDeleted()
        viewModel.registerUndo(expense: deleted.expense, at: deleted.index)
    }

    @ViewBuilder
    private var undoBar: some View {
        if viewModel.pendingUndo != nil {
            UndoSnackbar {
                Task {
                    await viewModel.undoDelete()
                    navigation.dataDidChange()
                }
            }
            .padding(.horizontal, 18)
            // 떠 있는 탭바 위에 놓는다.
            .padding(.bottom, AppSpacing.tabBarBottom + AppSpacing.tabBarHeight + 18)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - 날짜 이동

    private func step(_ days: Int) {
        navigation.selectedDate = CalendarDay.adding(days: days, to: navigation.selectedDate)
    }

    private func goToday() {
        navigation.selectedDate = CalendarDay.today()
    }

    private struct LoadKey: Hashable {
        let day: Date
        let version: Int
    }
}
