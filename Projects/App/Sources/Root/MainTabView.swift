import SwiftUI
import Monthly
import DesignSystem
import Domain
import Persistence
import Daily
import Editor
import Statistics
import Settings

struct MainTabView: View {
    let stack: PersistenceStack

    @Environment(AppNavigation.self) private var navigation

    var body: some View {
        @Bindable var navigation = navigation

        ZStack(alignment: .bottom) {
            // 탭바가 떠 있으므로 내용은 화면 끝까지 흐르고, 아래에서 올라오는
            // 그라데이션이 탭바 뒤로 지나가는 글자를 가린다.
            screen
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // 아직 새 레이아웃으로 옮기지 않은 탭은 탭바 높이만큼 아래를 비워 둔다.
                .padding(.bottom, navigation.selectedTab == .daily ? 0 : AppSpacing.tabBarHeight)

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                AppColor.bottomFade
                    .frame(height: AppSpacing.bottomFadeHeight)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            AppTabBar(selection: $navigation.selectedTab) {
                navigation.presentCreateEditor()
            }
        }
        .background(AppColor.background)
        .sheet(item: $navigation.editorRoute) { route in
            ExpenseEditorView(
                route: route,
                expenseRepository: stack.expenses,
                categoryRepository: stack.categories,
                settingsRepository: stack.settings,
                onSaved: { navigation.dataDidChange() },
                onDeleted: { expense, index in
                    navigation.expenseDidDelete(expense, at: index)
                }
            )
        }
    }

    @ViewBuilder
    private var screen: some View {
        switch navigation.selectedTab {
        case .daily:
            DailyView(
                expenseRepository: stack.expenses,
                categoryRepository: stack.categories
            )
        case .monthly:
            MonthlyView(expenseRepository: stack.expenses)
        case .statistics:
            StatisticsView(
                expenseRepository: stack.expenses,
                categoryRepository: stack.categories,
                settingsRepository: stack.settings
            )
        case .settings:
            SettingsView(
                settingsRepository: stack.settings,
                categoryRepository: stack.categories,
                dataResetting: stack.reset
            )
        }
    }
}
