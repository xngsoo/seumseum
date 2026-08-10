import SwiftUI
import DesignSystem
import Domain
import Persistence

struct MainTabView: View {
    let stack: PersistenceStack

    @Environment(AppNavigation.self) private var navigation
    @State private var isEditorPresented = false

    var body: some View {
        @Bindable var navigation = navigation

        ZStack(alignment: .bottom) {
            screen
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, AppSpacing.tabBarHeight)

            AppTabBar(selection: $navigation.selectedTab) {
                isEditorPresented = true
            }
        }
        .background(AppColor.background)
        .sheet(isPresented: $isEditorPresented) {
            PlaceholderScreen(title: "지출 추가", detail: "5단계에서는 자리만 잡습니다")
        }
    }

    @ViewBuilder
    private var screen: some View {
        switch navigation.selectedTab {
        case .daily:
            PlaceholderScreen(title: "일별", detail: "탭 1 — 그날의 소비 내역")
        case .monthly:
            PlaceholderScreen(title: "달력", detail: "탭 2 — 월 그리드와 일별 합계")
        case .statistics:
            PlaceholderScreen(title: "통계", detail: "탭 3 — 급여 주기별 분석")
        case .settings:
            PlaceholderScreen(title: "설정", detail: "탭 4 — 카테고리·급여일")
        }
    }
}
