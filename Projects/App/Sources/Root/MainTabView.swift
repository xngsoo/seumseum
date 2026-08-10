import SwiftUI
import Monthly
import DesignSystem
import Domain
import Persistence
import Daily
import Editor
import Statistics

struct MainTabView: View {
    let stack: PersistenceStack

    @Environment(AppNavigation.self) private var navigation

    var body: some View {
        @Bindable var navigation = navigation

        ZStack(alignment: .bottom) {
            screen
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, AppSpacing.tabBarHeight)

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
                onSaved: { navigation.dataDidChange() }
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
            PlaceholderScreen(title: "설정", detail: "탭 4 — 카테고리·급여일")
        }
    }
}
