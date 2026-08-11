import SwiftUI
import DesignSystem

/// 제목 + 카드 + 각주 한 덩어리. `List` 의 `Section` 을 대신한다.
struct SettingsSection<Content: View, Footer: View>: View {
    let title: String?
    @ViewBuilder let content: () -> Content
    @ViewBuilder let footer: () -> Footer

    init(
        _ title: String? = nil,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer
    ) {
        self.title = title
        self.content = content
        self.footer = footer
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if let title {
                Text(title)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(.horizontal, AppSpacing.sm)
            }

            VStack(spacing: 0) {
                content()
            }
            .background(
                AppColor.surface,
                in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
            )

            footer()
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.sm)
        }
        .padding(.horizontal, AppSpacing.lg)
    }
}

extension SettingsSection where Footer == EmptyView {
    init(_ title: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.init(title, content: content, footer: { EmptyView() })
    }
}

#Preview {
    SettingsSection("급여 주기") {
        SettingsRow("급여일 사용", showsSeparator: false) {
            Toggle("", isOn: .constant(true))
                .labelsHidden()
                .tint(AppColor.accent)
        }
    } footer: {
        Text("월급날을 기준으로 한 달을 묶어 통계를 봅니다.")
    }
    .padding(.vertical, AppSpacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColor.background)
}
