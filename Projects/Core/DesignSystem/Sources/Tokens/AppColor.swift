import SwiftUI
import Shared

public enum AppColor {
    public static let background = DesignSystemAsset.background.swiftUIColor
    public static let surface = DesignSystemAsset.surface.swiftUIColor
    public static let textPrimary = DesignSystemAsset.textPrimary.swiftUIColor
    public static let textSecondary = DesignSystemAsset.textSecondary.swiftUIColor
    public static let separator = DesignSystemAsset.separator.swiftUIColor
    public static let accent = DesignSystemAsset.accent.swiftUIColor

    public static func category(_ token: ColorToken) -> Color {
        switch token {
        case .orange: DesignSystemAsset.categoryOrange.swiftUIColor
        case .brown: DesignSystemAsset.categoryBrown.swiftUIColor
        case .blue: DesignSystemAsset.categoryBlue.swiftUIColor
        case .pink: DesignSystemAsset.categoryPink.swiftUIColor
        case .green: DesignSystemAsset.categoryGreen.swiftUIColor
        case .red: DesignSystemAsset.categoryRed.swiftUIColor
        case .purple: DesignSystemAsset.categoryPurple.swiftUIColor
        case .gray: DesignSystemAsset.categoryGray.swiftUIColor
        }
    }
}
