import SwiftUI
import UIKit

/// 글자 토큰.
///
/// 디자인이 지정한 크기를 그대로 쓰되 글자 크기 설정을 따라가야 해서,
/// `UIFontMetrics` 로 기준 크기를 키운 폰트를 SwiftUI 로 감싼다.
/// 텍스트 스타일만 쓰면 42pt 같은 중간값을 낼 수 없다.
public enum AppFont {

    // MARK: - 금액

    /// 화면 한가운데 놓이는 그날의 총액.
    public static let amountHero = scaled(42, weight: .semibold, relativeTo: .largeTitle, digitsAligned: true)
    public static let amountLarge = scaled(28, weight: .semibold, relativeTo: .title1, digitsAligned: true)
    /// 목록 행 오른쪽 금액.
    public static let amount = scaled(16, weight: .medium, relativeTo: .body, digitsAligned: true)
    public static let amountSmall = scaled(11, weight: .medium, relativeTo: .caption2, digitsAligned: true)

    // MARK: - 제목

    public static let screenTitle = scaled(26, weight: .semibold, relativeTo: .title2)
    /// 날짜 헤더처럼 화면 제목보다 한 단계 작은 자리.
    public static let sectionTitle = scaled(22, weight: .semibold, relativeTo: .title3)
    /// 모달 제목.
    public static let sheetTitle = scaled(15, weight: .semibold, relativeTo: .body)

    // MARK: - 본문

    public static let rowTitle = scaled(15.5, weight: .medium, relativeTo: .body)
    public static let rowDetail = scaled(13.5, weight: .regular, relativeTo: .subheadline)
    /// 행 아래 붙는 카테고리 이름처럼 한 단계 더 작은 보조 문구.
    public static let rowCaption = scaled(12, weight: .regular, relativeTo: .caption1)
    public static let caption = scaled(11.5, weight: .regular, relativeTo: .caption1)
    /// `TOTAL` 처럼 자간을 벌려 쓰는 대문자 머리글. 자간은 쓰는 쪽에서 `.tracking` 으로 준다.
    public static let overline = scaled(11.5, weight: .regular, relativeTo: .caption2)
    /// 탭바 라벨.
    public static let tabLabel = scaled(9.5, weight: .regular, relativeTo: .caption2)

    // MARK: - UIKit 짝

    /// UIKit 으로 감싼 컴포넌트용 `rowTitle` 짝.
    public static var uiRowTitle: UIFont {
        UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15.5, weight: .medium))
    }

    private static func scaled(
        _ size: CGFloat,
        weight: UIFont.Weight,
        relativeTo style: UIFont.TextStyle,
        digitsAligned: Bool = false
    ) -> Font {
        let base = digitsAligned
            ? UIFont.monospacedDigitSystemFont(ofSize: size, weight: weight)
            : UIFont.systemFont(ofSize: size, weight: weight)
        return Font(UIFontMetrics(forTextStyle: style).scaledFont(for: base))
    }
}
