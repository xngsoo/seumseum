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

            if !navigation.isSubScreenPresented {
                AppTabBar(
                    selection: $navigation.selectedTab,
                    onAdd: { navigation.presentCreateEditor() },
                    onReselect: { navigation.requestHome() }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy(duration: 0.25), value: navigation.isSubScreenPresented)
        // 탭이 바뀌면 서브 화면도 함께 사라진다. 탭바가 감춰진 채로 남지 않게 한다.
        .onChange(of: navigation.selectedTab) { _, _ in
            navigation.isSubScreenPresented = false
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
