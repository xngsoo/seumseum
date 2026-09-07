import SwiftUI
import DesignSystem

/// 묶음 안의 한 줄. 오른쪽에는 값·토글·메뉴 무엇이든 올 수 있다.
/// 마지막 줄만 `showsSeparator: false` 로 두면 묶음 바닥에 선이 겹치지 않는다.
struct SettingsRow<Trailing: View>: View {
    let title: String
    let titleColor: Color
    let showsSeparator: Bool
    let showsChevron: Bool
    let action: (() -> Void)?
    @ViewBuilder let trailing: () -> Trailing

    init(
        _ title: String,
        titleColor: Color = AppColor.textPrimary,
        showsSeparator: Bool = true,
        showsChevron: Bool = false,
        action: (() -> Void)? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.titleColor = titleColor
        self.showsSeparator = showsSeparator
        self.showsChevron = showsChevron
        self.action = action
        self.trailing = trailing
    }

    var body: some View {
        if let action {
            content
                .contentShape(Rectangle())
                .onTapGesture(perform: action)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { action() }
        } else {
            content
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text(title)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(titleColor)

                Spacer(minLength: AppSpacing.sm)
                trailing()

                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppColor.textDim)
                }
            }
            .padding(.horizontal, AppSpacing.screenMargin)
            .padding(.vertical, 15)

            if showsSeparator {
                Rectangle()
                    .fill(AppColor.separatorFaint)
                    .frame(height: 1)
            }
        }
    }
}

extension SettingsRow where Trailing == EmptyView {
    init(
        _ title: String,
        titleColor: Color = AppColor.textPrimary,
        showsSeparator: Bool = true,
        showsChevron: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.init(
            title,
            titleColor: titleColor,
            showsSeparator: showsSeparator,
            showsChevron: showsChevron,
            action: action,
            trailing: { EmptyView() }
        )
    }
}

/// 줄 오른쪽에 값만 적을 때 쓰는 표기.
struct SettingsValue: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppFont.rowDetail)
            .foregroundStyle(AppColor.textFaint)
            .lineLimit(1)
    }
}

#Preview {
    VStack(spacing: 0) {
        SettingsRow(
            "카테고리 관리",
            showsChevron: true,
            action: {},
            trailing: { SettingsValue(text: "8개") }
        )
        SettingsRow("급여일") {
            SettingsValue(text: "매월 25일")
        }
        SettingsRow("데이터 초기화", titleColor: AppColor.category(.red), showsSeparator: false, action: {})
    }
    .background(AppColor.surface)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(AppColor.background)
}
