import SwiftUI
import DesignSystem
import Domain

/// 화면 위에 떠 있는 알약형 탭바. 가운데 추가 버튼은 탭이 아니라 액션이라
/// 탭 자리를 차지하지 않고 막대 위로 걸쳐 놓는다.
struct AppTabBar: View {
    @Binding var selection: AppTab
    let onAdd: () -> Void

    /// 추가 버튼이 막대 위로 올라간 높이. 버튼과 막대의 중심 거리다.
    private let addButtonLift: CGFloat = 38

    var body: some View {
        bar
            .overlay(alignment: .center) {
                addButton.offset(y: -addButtonLift)
            }
            .padding(.horizontal, AppSpacing.tabBarInset)
            .padding(.bottom, AppSpacing.tabBarBottom)
    }

    private var bar: some View {
        HStack(spacing: 0) {
            tabButton(.daily)
            // 가운데 추가 버튼이 지나갈 자리를 양쪽에서 비운다.
            tabButton(.monthly).padding(.trailing, 34)
            tabButton(.statistics).padding(.leading, 34)
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
            selection = tab
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
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(AppColor.accent, in: Circle())
                .shadow(color: AppColor.accent.opacity(0.36), radius: 9, y: 6)
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
        AppTabBar(selection: $selection, onAdd: {})
    }
    .background(AppColor.background)
}
