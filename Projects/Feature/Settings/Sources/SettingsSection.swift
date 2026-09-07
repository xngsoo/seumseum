import SwiftUI
import DesignSystem

/// 제목 + 줄 묶음 + 각주 한 덩어리. `List` 의 `Section` 을 대신한다.
///
/// 줄 묶음은 화면 좌우 끝까지 채우고 위아래에만 실선을 둔다. 카드로 띄우면
/// 설정처럼 줄이 길게 이어지는 화면에서 모서리가 계속 눈에 걸린다.
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
        VStack(alignment: .leading, spacing: 0) {
            if let title {
                Text(title)
                    .font(AppFont.caption)
                    .tracking(1.2)
                    .foregroundStyle(AppColor.textFaint)
                    .padding(.horizontal, AppSpacing.screenMargin)
                    .padding(.bottom, 9)
            }

            VStack(spacing: 0) {
                content()
            }
            .background(AppColor.surface)
            .overlay(alignment: .top) { hairline }
            .overlay(alignment: .bottom) { hairline }

            footer()
                .font(AppFont.caption)
                .lineSpacing(3)
                .foregroundStyle(AppColor.textFaint)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.screenMargin)
                .padding(.top, 9)
        }
    }

    private var hairline: some View {
        Rectangle()
            .fill(AppColor.separator)
            .frame(height: 1)
    }
}

extension SettingsSection where Footer == EmptyView {
    init(_ title: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.init(title, content: content, footer: { EmptyView() })
    }
}

#Preview {
    SettingsSection("통계") {
        SettingsRow("급여일 사용", showsSeparator: false) {
            Toggle("", isOn: .constant(true))
                .labelsHidden()
                .tint(AppColor.accent)
        }
    } footer: {
        Text("켜면 통계 탭이 달력상의 월 대신 급여일 기준 주기로 집계됩니다.\n일별·월별 탭과 기록 자체는 바뀌지 않습니다.")
    }
    .padding(.vertical, AppSpacing.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(AppColor.background)
}
