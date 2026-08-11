import SwiftUI
import DesignSystem

/// 설정 계열 화면의 제목 바. 시스템 내비게이션 바 대신 쓴다.
/// 다른 탭들도 각자 헤더를 그리고 있어서 결이 같다.
struct SettingsHeader<Trailing: View>: View {
    let title: String
    let onBack: (() -> Void)?
    @ViewBuilder let trailing: () -> Trailing

    init(
        title: String,
        onBack: (() -> Void)? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.onBack = onBack
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColor.textPrimary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("뒤로")
            }

            Text(title)
                .font(AppFont.screenTitle)
                .foregroundStyle(AppColor.textPrimary)

            Spacer(minLength: AppSpacing.sm)
            trailing()
        }
        .padding(.horizontal, AppSpacing.screenMargin)
        .padding(.vertical, AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surface)
    }
}

extension SettingsHeader where Trailing == EmptyView {
    init(title: String, onBack: (() -> Void)? = nil) {
        self.init(title: title, onBack: onBack, trailing: { EmptyView() })
    }
}

#Preview {
    VStack(spacing: 0) {
        SettingsHeader(title: "설정")
        Divider().overlay(AppColor.separator)
        SettingsHeader(title: "카테고리 관리", onBack: {}) {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColor.accent)
        }
        Spacer()
    }
    .background(AppColor.background)
}
