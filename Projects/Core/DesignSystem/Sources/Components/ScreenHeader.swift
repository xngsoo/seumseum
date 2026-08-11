import SwiftUI

/// 시스템 내비게이션 바 대신 쓰는 제목 바.
/// 제목은 항상 가운데에 두어 좌우 버튼 폭이 달라도 흔들리지 않는다.
public struct ScreenHeader<Trailing: View>: View {

    public enum Style {
        /// 탭 최상위 화면. 내용 위에 한 겹 얹힌 것처럼 보인다.
        case screen
        /// 밀어서 들어온 화면. 바탕은 같고 제목만 한 단계 작다.
        case subScreen
        /// 모달. 아래 내용과 같은 바탕이라 경계가 드러나지 않는다.
        case sheet
    }

    public enum Leading {
        case none
        /// 밀어서 들어온 화면
        case back(() -> Void)
        /// 모달
        case close(() -> Void)
    }

    private let title: String
    private let style: Style
    private let leading: Leading
    private let trailing: () -> Trailing

    public init(
        _ title: String,
        style: Style = .screen,
        leading: Leading = .none,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.style = style
        self.leading = leading
        self.trailing = trailing
    }

    public var body: some View {
        ZStack {
            Text(title)
                .font(titleFont)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)

            HStack(spacing: AppSpacing.sm) {
                leadingButton
                Spacer(minLength: AppSpacing.sm)
                trailing()
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, topPadding)
        .padding(.bottom, AppSpacing.md)
        .frame(maxWidth: .infinity)
        .background(background)
    }

    private var titleFont: Font {
        switch style {
        case .screen: AppFont.screenTitle
        case .subScreen, .sheet: AppFont.sheetTitle
        }
    }

    private var background: Color {
        switch style {
        case .screen, .subScreen: AppColor.surface
        case .sheet: AppColor.background
        }
    }

    /// 시트는 위쪽 여백을 더 준다. 그래야 제목이 시트 윗변에 붙지 않고
    /// 윗변과 첫 내용 사이 가운데쯤에 놓인다.
    private var topPadding: CGFloat {
        switch style {
        case .screen, .subScreen: AppSpacing.md
        case .sheet: AppSpacing.xl
        }
    }

    @ViewBuilder
    private var leadingButton: some View {
        switch leading {
        case .none:
            EmptyView()
        case let .back(action):
            Button(action: action) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("뒤로")
        case let .close(action):
            Button(action: action) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("닫기")
        }
    }
}

public extension ScreenHeader where Trailing == EmptyView {
    init(_ title: String, style: Style = .screen, leading: Leading = .none) {
        self.init(title, style: style, leading: leading, trailing: { EmptyView() })
    }
}

#Preview {
    VStack(spacing: AppSpacing.lg) {
        ScreenHeader("설정")
        ScreenHeader("카테고리 관리", style: .subScreen, leading: .back({})) {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColor.accent)
                .frame(width: 32, height: 32)
        }
        ScreenHeader("지출 추가", style: .sheet, leading: .close({}))
        Spacer()
    }
    .background(AppColor.background)
}
