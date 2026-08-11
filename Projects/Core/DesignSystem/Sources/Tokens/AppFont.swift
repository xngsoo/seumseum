import SwiftUI
import UIKit

public enum AppFont {
    public static let amountLarge = Font.system(.largeTitle, design: .rounded, weight: .bold).monospacedDigit()
    public static let amount = Font.system(.body, design: .rounded, weight: .semibold).monospacedDigit()
    public static let amountSmall = Font.system(.caption2, design: .rounded, weight: .medium).monospacedDigit()
    public static let screenTitle = Font.system(.title2, design: .rounded, weight: .bold)
    /// 모달 제목. 화면 제목보다 한 단계 작다.
    public static let sheetTitle = Font.system(.body, design: .rounded, weight: .semibold)
    public static let rowTitle = Font.system(.body, weight: .medium)
    public static let rowDetail = Font.system(.subheadline)
    public static let caption = Font.system(.caption)
    
    /// UIKit 으로 감싼 컴포넌트용 `rowTitle` 짝. 17pt 는 `.body` 의 기본 크기다.
    public static var uiRowTitle: UIFont {
        UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .medium))
    }
}
