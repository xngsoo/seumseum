import SwiftUI
import DesignSystem

/// 카드 안의 한 줄. 오른쪽에는 값·토글·메뉴 무엇이든 올 수 있다.
/// 마지막 줄만 `showsSeparator: false` 로 두면 카드 바닥에 선이 남지 않는다.
struct SettingsRow<Trailing: View>: View {
    let title: String
    let systemImage: String?
    let titleColor: Color
    let showsSeparator: Bool
    let showsChevron: Bool
    let action: (() -> Void)?
    @ViewBuilder let trailing: () -> Trailing

    init(
        _ title: String,
        systemImage: String? = nil,
        titleColor: Color = AppColor.textPrimary,
        showsSeparator: Bool = true,
        showsChevron: Bool = false,
        action: (() -> Void)? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.systemImage = systemImage
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
        } else {
            content
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppSpacing.md) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColor.accent)
                        .frame(width: 24)
                }

                Text(title)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(titleColor)

                Spacer(minLength: AppSpacing.sm)
                trailing()

                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColor.separator)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .frame(minHeight: 52)

            if showsSeparator {
                Divider()
                    .overlay(AppColor.separator)
                    .padding(.leading, AppSpacing.lg)
            }
        }
    }
}

extension SettingsRow where Trailing == EmptyView {
    init(
        _ title: String,
        systemImage: String? = nil,
        titleColor: Color = AppColor.textPrimary,
        showsSeparator: Bool = true,
        showsChevron: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.init(
            title,
            systemImage: systemImage,
            titleColor: titleColor,
            showsSeparator: showsSeparator,
            showsChevron: showsChevron,
            action: action,
            trailing: { EmptyView() }
        )
    }
}

#Preview {
    VStack(spacing: 0) {
        SettingsRow("카테고리 관리", systemImage: "square.grid.2x2", showsChevron: true, action: {})
        SettingsRow("급여일") {
            Text("매월 25일")
                .font(AppFont.rowDetail)
                .foregroundStyle(AppColor.textSecondary)
        }
        SettingsRow("데이터 초기화", titleColor: AppColor.category(.red), showsSeparator: false, action: {})
    }
    .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
    .padding()
    .background(AppColor.background)
}
