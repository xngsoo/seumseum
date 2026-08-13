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
            // 탭바가 떠 있으므로 내용은 화면 끝까지 흐른다.
            // 탭바 뒤로 지나가는 글자를 가리는 일은 화면마다 알아서 한다.
            screen
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // 아직 새 레이아웃으로 옮기지 않은 탭은 탭바 높이만큼 아래를 비워 둔다.
                .padding(.bottom, movedToFloatingTabBar ? 0 : AppSpacing.tabBarHeight)

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

    /// 스스로 탭바 자리를 비워 두는 탭. 나머지는 아직 옛 레이아웃이다.
    private var movedToFloatingTabBar: Bool {
        switch navigation.selectedTab {
        case .daily, .monthly, .statistics: true
        case .settings: false
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
