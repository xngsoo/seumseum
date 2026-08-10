import Foundation

/// 사용자 설정. 지금은 급여 주기만 담고, 탭 4가 붙으면서 확장된다.
public struct AppSettings: Hashable, Sendable {
    public var payPeriod: PayPeriodSetting
    /// 급여일 안내 다이얼로그를 이미 보여줬는지. 처음 켤 때만 보여주기 위한 값이다.
    public var hasSeenPaydayNotice: Bool
    /// 정액 품목 분리 규칙. nil 이면 기능이 꺼진 상태다.
    public var splitItem: SplitItem?

    public init(
        payPeriod: PayPeriodSetting = .calendarMonth,
        hasSeenPaydayNotice: Bool = false,
        splitItem: SplitItem? = nil
    ) {
        self.payPeriod = payPeriod
        self.hasSeenPaydayNotice = hasSeenPaydayNotice
        self.splitItem = splitItem
    }

    public static let `default` = AppSettings()
}
