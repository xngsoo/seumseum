import SwiftUI
import UIKit

/// 글자 토큰.
///
/// 크기를 고정한다. 화면마다 격자·칩·키패드처럼 폭과 높이가 정해진 배치가 많아,
/// 글자만 커지면 줄이 겹치거나 잘린다. 시스템 글자 크기 설정은 뿌리 화면에서
/// `dynamicTypeSize` 로 함께 묶어 둔다.
public enum AppFont {

    // MARK: - 금액

    /// 화면 한가운데 놓이는 그날의 총액.
    public static let amountHero = fixed(42, weight: .semibold, digitsAligned: true)
    public static let amountLarge = fixed(28, weight: .semibold, digitsAligned: true)
    /// 카드 안에 놓이는 합계.
    public static let amountMedium = fixed(22, weight: .semibold, digitsAligned: true)
    /// 목록 행 오른쪽 금액.
    public static let amount = fixed(16, weight: .medium, digitsAligned: true)
    public static let amountSmall = fixed(11, weight: .medium, digitsAligned: true)
    /// 달력 칸의 날짜.
    public static let calendarDay = fixed(13, weight: .medium, digitsAligned: true)
    /// 달력 칸 아래의 그날 합계. 칸 폭에 맞춰 가장 작다.
    public static let calendarAmount = fixed(9.5, weight: .medium, digitsAligned: true)

    // MARK: - 제목

    public static let screenTitle = fixed(26, weight: .semibold)
    /// 날짜 헤더처럼 화면 제목보다 한 단계 작은 자리.
    public static let sectionTitle = fixed(22, weight: .semibold)
    /// 좌우 화살표 사이에 놓이는 제목. 달 이름처럼 값이 길어지는 자리에 쓴다.
    public static let navTitle = fixed(19, weight: .semibold)
    /// 기간 제목. 아래에 기준 설명이 한 줄 더 붙으므로 `navTitle` 보다 작다.
    public static let periodTitle = fixed(16, weight: .semibold, digitsAligned: true)
    /// 카드 안의 값. 라벨 아래 한 줄로 놓인다.
    public static let tileValue = fixed(17, weight: .semibold, digitsAligned: true)
    /// 모달 제목.
    public static let sheetTitle = fixed(15, weight: .semibold)

    // MARK: - 본문

    public static let rowTitle = fixed(15.5, weight: .medium)
    public static let rowDetail = fixed(13.5, weight: .regular)
    /// 행 아래 붙는 카테고리 이름처럼 한 단계 더 작은 보조 문구.
    public static let rowCaption = fixed(12, weight: .regular)
    public static let caption = fixed(11.5, weight: .regular)
    /// `TOTAL` 처럼 자간을 벌려 쓰는 대문자 머리글. 자간은 쓰는 쪽에서 `.tracking` 으로 준다.
    public static let overline = fixed(11.5, weight: .regular)
    /// 탭바 라벨.
    public static let tabLabel = fixed(9.5, weight: .regular)

    // MARK: - UIKit 짝

    /// UIKit 으로 감싼 컴포넌트용 `rowTitle` 짝.
    public static var uiRowTitle: UIFont {
        .systemFont(ofSize: 15.5, weight: .medium)
    }

    /// `rowDetail` 을 굵게 쓴 값의 UIKit 짝. 카드 안에서 값을 적는 자리에 쓴다.
    public static var uiRowValue: UIFont {
        .systemFont(ofSize: 13.5, weight: .medium)
    }

    private static func fixed(
        _ size: CGFloat,
        weight: Font.Weight,
        digitsAligned: Bool = false
    ) -> Font {
        let font = Font.system(size: size, weight: weight)
        return digitsAligned ? font.monospacedDigit() : font
    }
}
