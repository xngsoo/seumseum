import Observation
import Shared

/// 지금 화면에 적용된 색 기조와 밝기.
///
/// `AppColor` 의 색은 정적으로 읽히기 때문에, 값만 바꾸면 이미 그려진 화면은 따라오지
/// 않는다. 이 저장소를 함께 바꾸고 뿌리 화면이 그 값을 신원으로 삼아 다시 그린다.
/// 토큰을 먼저 바꾸고 화면을 나중에 바꾸는 순서를 여기서 지킨다.
@MainActor
@Observable
public final class AppearanceStore {

    public private(set) var theme: AppTheme = .default
    public private(set) var isDarkMode = false

    public init() {}

    public func apply(theme: AppTheme, isDarkMode: Bool) {
        AppColor.theme = theme
        self.theme = theme
        self.isDarkMode = isDarkMode
    }
}
