import SwiftUI
import DesignSystem
import Domain

/// 화면 위에 떠 있는 알약형 탭바. 가운데 추가 버튼은 탭이 아니라 액션이지만
/// 다른 탭과 같은 줄에 같은 폭으로 놓는다.
struct AppTabBar: View {
    @Binding var selection: AppTab
    let onAdd: () -> Void
    /// 이미 열려 있는 탭을 다시 눌렀을 때.
    let onReselect: () -> Void

    var body: some View {
        bar
            .padding(.horizontal, AppSpacing.tabBarInset)
            .padding(.bottom, AppSpacing.tabBarBottom)
    }

    private var bar: some View {
        HStack(spacing: 0) {
            tabButton(.daily)
            tabButton(.monthly)
            addButton
            tabButton(.statistics)
            tabButton(.settings)
        }
        .frame(height: AppSpacing.tabBarHeight)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .background(AppColor.surface.opacity(0.92), in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(AppColor.separator, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 9, y: 4)
    }

    private func tabButton(_ tab: AppTab) -> some View {
        Button {
            // 같은 탭을 다시 누르면 옮기는 대신 그 화면을 오늘 자리로 되돌린다.
            if selection == tab {
                onReselect()
            } else {
                selection = tab
            }
        } label: {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: tab.symbolName)
                    .font(.system(size: 17, weight: .regular))
                Text(tab.title)
                    .font(AppFont.tabLabel)
            }
            .foregroundStyle(selection == tab ? AppColor.accent : AppColor.textFaint)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(selection == tab ? [.isSelected] : [])
    }

    private var addButton: some View {
        Button(action: onAdd) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(AppColor.accent, in: Circle())
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("지출 추가")
    }
}

private extension AppTab {
    var title: String {
        switch self {
        case .daily: "일별"
        case .monthly: "월별"
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
        AppTabBar(selection: $selection, onAdd: {}, onReselect: {})
    }
    .background(AppColor.background)
}
