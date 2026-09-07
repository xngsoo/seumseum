import Foundation

/// 앱 전체의 색 기조. 실제 색값은 DesignSystem이 이 색상각에서 계산한다.
///
/// 액센트뿐 아니라 바탕과 글자의 아주 옅은 기운까지 같은 각도에서 나온다.
/// 그래서 화면 전체가 한 덩어리로 보인다.
public enum AppTheme: String, CaseIterable, Sendable {
    case olive
    case ink
    case clay
    case pine

    public static let `default`: AppTheme = .olive

    public var displayName: String {
        switch self {
        case .olive: "올리브"
        case .ink: "잉크 블루"
        case .clay: "테라코타"
        case .pine: "파인 그린"
        }
    }

    /// OKLCH 색상각(도).
    public var hue: Double {
        switch self {
        case .olive: 85
        case .ink: 250
        case .clay: 35
        case .pine: 162
        }
    }
}
