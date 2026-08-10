import SwiftUI
import DesignSystem
import Domain

struct AppTabBar: View {
    @Binding var selection: AppTab
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.daily)
            tabButton(.monthly)
            addButton
            tabButton(.statistics)
            tabButton(.settings)
        }
        .frame(height: AppSpacing.tabBarHeight)
        .background(AppColor.surface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColor.separator)
                .frame(height: 0.5)
        }
    }

    private func tabButton(_ tab: AppTab) -> some View {
        Button {
            selection = tab
        } label: {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: tab.symbolName)
                    .font(.system(size: 20))
                Text(tab.title)
                    .font(AppFont.caption)
            }
            .foregroundStyle(selection == tab ? AppColor.accent : AppColor.textSecondary)
            .frame(maxWidth: .infinity)
        }
        .accessibilityLabel(tab.title)
    }

    private var addButton: some View {
        Button(action: onAdd) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppColor.surface)
                .frame(width: 52, height: 52)
                .background(AppColor.accent, in: Circle())
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("지출 추가")
    }
}

private extension AppTab {
    var title: String {
        switch self {
        case .daily: "일별"
        case .monthly: "달력"
        case .statistics: "통계"
        case .settings: "설정"
        }
    }

    var symbolName: String {
        switch self {
        case .daily: "list.bullet"
        case .monthly: "calendar"
        case .statistics: "chart.pie"
        case .settings: "gearshape"
        }
    }
}

#Preview {
    @Previewable @State var selection = AppTab.daily
    return VStack {
        Spacer()
        AppTabBar(selection: $selection, onAdd: {})
    }
}
