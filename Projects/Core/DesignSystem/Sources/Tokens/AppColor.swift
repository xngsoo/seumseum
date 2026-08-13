import SwiftUI
import UIKit
import Shared

/// 색 토큰. 실제 값은 에셋 카탈로그가 라이트/다크 한 쌍으로 들고 있다.
///
/// 팔레트는 OKLCH 한 축에서 파생한다. 중립색은 액센트와 같은 색상각(85°)에
/// 아주 낮은 채도를 얹어 화면 전체가 한 덩어리로 보이게 했다.
public enum AppColor {

    // MARK: - 바탕과 표면

    public static let background = DesignSystemAsset.background.swiftUIColor
    public static let surface = DesignSystemAsset.surface.swiftUIColor
    /// 바탕에서 한 단계 떠 있는 면. 다이얼로그처럼 표면 위에 겹치는 것에 쓴다.
    public static let surfaceRaised = DesignSystemAsset.surfaceRaised.swiftUIColor
    /// 바탕보다 한 단계 가라앉은 면. 키패드 트레이처럼 눌러 담는 곳에 쓴다.
    public static let surfaceSunken = DesignSystemAsset.surfaceSunken.swiftUIColor

    // MARK: - 글자

    public static let textPrimary = DesignSystemAsset.textPrimary.swiftUIColor
    /// 본문 다음가는 강조. 통계 범례처럼 제목은 아니지만 읽혀야 하는 곳.
    public static let textStrong = DesignSystemAsset.textStrong.swiftUIColor
    public static let textSecondary = DesignSystemAsset.textSecondary.swiftUIColor
    public static let textMuted = DesignSystemAsset.textMuted.swiftUIColor
    /// 섹션 머리글, 단위, 캡션.
    public static let textFaint = DesignSystemAsset.textFaint.swiftUIColor
    /// 비활성 상태. 눌러도 반응하지 않는다는 뜻으로만 쓴다.
    public static let textDim = DesignSystemAsset.textDim.swiftUIColor

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

    public static let accent = DesignSystemAsset.accent.swiftUIColor
    /// 눌린 상태의 액센트.
    public static let accentDeep = DesignSystemAsset.accentDeep.swiftUIColor
    /// 바탕 위 글자로 쓰는 액센트. 대비를 위해 액센트보다 어둡다.
    public static let accentInk = DesignSystemAsset.accentInk.swiftUIColor
    /// 선택 상태의 옅은 배경.
    public static let accentSoft = DesignSystemAsset.accentSoft.swiftUIColor
    /// 어두운 스낵바 위에서 쓰는 액센트.
    public static let accentUndo = DesignSystemAsset.accentUndo.swiftUIColor

    // MARK: - 스낵바

    public static let snackbarSurface = DesignSystemAsset.snackbarSurface.swiftUIColor
    public static let snackbarLabel = DesignSystemAsset.snackbarLabel.swiftUIColor

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

    public static var uiTextPrimary: UIColor { DesignSystemAsset.textPrimary.color }
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
