import SwiftUI

public enum AppFont {
    public static let amountLarge = Font.system(.largeTitle, design: .rounded, weight: .bold).monospacedDigit()
    public static let amount = Font.system(.body, design: .rounded, weight: .semibold).monospacedDigit()
    public static let amountSmall = Font.system(.caption2, design: .rounded, weight: .medium).monospacedDigit()
    public static let screenTitle = Font.system(.title2, design: .rounded, weight: .bold)
    public static let rowTitle = Font.system(.body, weight: .medium)
    public static let rowDetail = Font.system(.subheadline)
    public static let caption = Font.system(.caption)
}
