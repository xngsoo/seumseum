import Foundation
import Shared

/// 사용자 설정. 지금은 급여 주기만 담고, 탭 4가 붙으면서 확장된다.
public struct AppSettings: Hashable, Sendable {
    public var payPeriod: PayPeriodSetting
    /// 급여일 안내 다이얼로그를 이미 보여줬는지. 처음 켤 때만 보여주기 위한 값이다.
    public var hasSeenPaydayNotice: Bool
    /// 정액 품목 분리 규칙. nil 이면 기능이 꺼진 상태다.
    public var splitItem: SplitItem?
    /// 색 기조.
    public var theme: AppTheme
    /// 어두운 화면으로 볼지. 끄면 시스템 설정과 무관하게 언제나 밝은 화면이다.
    public var isDarkMode: Bool

    public init(
        payPeriod: PayPeriodSetting = .calendarMonth,
        hasSeenPaydayNotice: Bool = false,
        splitItem: SplitItem? = nil,
        theme: AppTheme = .default,
        isDarkMode: Bool = false
    ) {
        self.payPeriod = payPeriod
        self.hasSeenPaydayNotice = hasSeenPaydayNotice
        self.splitItem = splitItem
        self.theme = theme
        self.isDarkMode = isDarkMode
    }

    public static let `default` = AppSettings()
}
