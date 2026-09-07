import SwiftUI
import UIKit
import Shared

/// 색 토큰.
///
/// 테마를 따라 달라지는 색은 `ThemePalette` 가 색상각 하나에서 계산한다.
/// 중립색까지 액센트와 같은 각도에 아주 낮은 채도를 얹어 화면이 한 덩어리로 보인다.
/// 카테고리·증감·선처럼 테마와 무관한 색은 에셋 카탈로그가 라이트/다크 한 쌍으로 들고 있다.
@MainActor
public enum AppColor {

    /// 지금 쓰는 색 기조. 바꾸면 그 뒤로 읽는 색이 모두 달라진다.
    /// 이미 그려진 화면까지 따라오게 하려면 `AppearanceStore` 로 바꿔야 한다.
    public static var theme: AppTheme = .default

    private static var palette: ThemePalette { ThemePalette(theme: theme) }

    // MARK: - 바탕과 표면

    public static var background: Color { palette.background }
    public static var surface: Color { palette.surface }
    /// 바탕에서 한 단계 떠 있는 면. 다이얼로그처럼 표면 위에 겹치는 것에 쓴다.
    public static var surfaceRaised: Color { palette.surfaceRaised }
    /// 바탕보다 한 단계 가라앉은 면. 키패드 트레이처럼 눌러 담는 곳에 쓴다.
    public static var surfaceSunken: Color { palette.surfaceSunken }

    // MARK: - 글자

    public static var textPrimary: Color { palette.textPrimary }
    /// 본문 다음가는 강조. 통계 범례처럼 제목은 아니지만 읽혀야 하는 곳.
    public static var textStrong: Color { palette.textStrong }
    public static var textSecondary: Color { palette.textSecondary }
    public static var textMuted: Color { palette.textMuted }
    /// 섹션 머리글, 단위, 캡션.
    public static var textFaint: Color { palette.textFaint }
    /// 비활성 상태. 눌러도 반응하지 않는다는 뜻으로만 쓴다.
    public static var textDim: Color { palette.textDim }

    // MARK: - 선과 상태

    public static let separator = DesignSystemAsset.separator.swiftUIColor
    /// 목록 행 사이처럼 촘촘히 반복되는 선.
    public static let separatorFaint = DesignSystemAsset.separatorFaint.swiftUIColor
    /// 구획을 나누는 굵은 선.
    public static let separatorStrong = DesignSystemAsset.separatorStrong.swiftUIColor
    public static let highlight = DesignSystemAsset.highlight.swiftUIColor
    public static let dashedStroke = DesignSystemAsset.dashedStroke.swiftUIColor
    public static let scrim = DesignSystemAsset.scrim.swiftUIColor

    // MARK: - 액센트

    public static var accent: Color { palette.accent }
    /// 눌린 상태의 액센트.
    public static var accentDeep: Color { palette.accentDeep }
    /// 바탕 위 글자로 쓰는 액센트. 대비를 위해 액센트보다 어둡다.
    public static var accentInk: Color { palette.accentInk }
    /// 선택 상태의 옅은 배경.
    public static var accentSoft: Color { palette.accentSoft }
    /// 어두운 스낵바 위에서 쓰는 액센트.
    public static var accentUndo: Color { palette.accentUndo }

    /// 테마 고르는 칸에 보여 주는 색. 지금 쓰는 테마와 무관하게 그 테마의 액센트다.
    public static func accent(of theme: AppTheme) -> Color {
        ThemePalette(theme: theme).accent
    }

    public static func accentSoft(of theme: AppTheme) -> Color {
        ThemePalette(theme: theme).accentSoft
    }

    // MARK: - 증감

    /// 지출이 늘었을 때. 가계부에서 증가는 반가운 소식이 아니라 붉은 쪽이다.
    public static let trendUp = DesignSystemAsset.trendUp.swiftUIColor
    public static let trendDown = DesignSystemAsset.trendDown.swiftUIColor

    // MARK: - 스낵바

    public static var snackbarSurface: Color { palette.snackbarSurface }
    public static var snackbarLabel: Color { palette.snackbarLabel }

    // MARK: - 카테고리

    public static func category(_ token: ColorToken) -> Color {
        categoryPalette[token]?.base ?? textMuted
    }

    /// 카테고리 색의 옅은 짝. 아이콘 배경처럼 색을 넓게 칠하는 곳에 쓴다.
    public static func categorySoft(_ token: ColorToken) -> Color {
        categoryPalette[token]?.soft ?? highlight
    }

    /// 토큰당 진한 색과 옅은 색이 한 쌍이다. 표로 두면 둘이 어긋날 일이 없다.
    private static let categoryPalette: [ColorToken: (base: Color, soft: Color)] = [
        .red: (DesignSystemAsset.categoryRed.swiftUIColor, DesignSystemAsset.categoryRedSoft.swiftUIColor),
        .orange: (DesignSystemAsset.categoryOrange.swiftUIColor, DesignSystemAsset.categoryOrangeSoft.swiftUIColor),
        .yellow: (DesignSystemAsset.categoryYellow.swiftUIColor, DesignSystemAsset.categoryYellowSoft.swiftUIColor),
        .lime: (DesignSystemAsset.categoryLime.swiftUIColor, DesignSystemAsset.categoryLimeSoft.swiftUIColor),
        .green: (DesignSystemAsset.categoryGreen.swiftUIColor, DesignSystemAsset.categoryGreenSoft.swiftUIColor),
        .teal: (DesignSystemAsset.categoryTeal.swiftUIColor, DesignSystemAsset.categoryTealSoft.swiftUIColor),
        .blue: (DesignSystemAsset.categoryBlue.swiftUIColor, DesignSystemAsset.categoryBlueSoft.swiftUIColor),
        .indigo: (DesignSystemAsset.categoryIndigo.swiftUIColor, DesignSystemAsset.categoryIndigoSoft.swiftUIColor),
        .purple: (DesignSystemAsset.categoryPurple.swiftUIColor, DesignSystemAsset.categoryPurpleSoft.swiftUIColor),
        .pink: (DesignSystemAsset.categoryPink.swiftUIColor, DesignSystemAsset.categoryPinkSoft.swiftUIColor),
        .brown: (DesignSystemAsset.categoryBrown.swiftUIColor, DesignSystemAsset.categoryBrownSoft.swiftUIColor),
        .gray: (DesignSystemAsset.categoryGray.swiftUIColor, DesignSystemAsset.categoryGraySoft.swiftUIColor)
    ]

    // MARK: - UIKit 짝

    public static var uiTextPrimary: UIColor { UIColor(palette.textPrimary) }
}

public extension View {

    /// 떠 있는 탭바 뒤로 흘러 들어가는 내용을 가린다.
    /// 화면 아래 끝에 붙으므로 안전 영역 밖까지 덮는다.
    func bottomFadeOverlay(height: CGFloat = AppSpacing.bottomFadeHeight) -> some View {
        overlay {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                AppColor.bottomFade.frame(height: height)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}

public extension AppColor {

    /// 떠 있는 탭바 뒤로 내용이 흘러 들어가는 것을 가리는 그라데이션.
    /// 위쪽은 완전히 투명해서 잘린 선이 보이지 않는다.
    static var bottomFade: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: background.opacity(0), location: 0),
                .init(color: background.opacity(0.92), location: 0.26),
                .init(color: background, location: 0.52)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
