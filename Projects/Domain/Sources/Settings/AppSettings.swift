import Foundation

/// 사용자 설정. 지금은 급여 주기만 담고, 탭 4가 붙으면서 확장된다.
public struct AppSettings: Hashable, Sendable {
    public var payPeriod: PayPeriodSetting
    /// 급여일 안내 다이얼로그를 이미 보여줬는지. 처음 켤 때만 보여주기 위한 값이다.
    public var hasSeenPaydayNotice: Bool

    public init(
        payPeriod: PayPeriodSetting = .calendarMonth,
        hasSeenPaydayNotice: Bool = false
    ) {
        self.payPeriod = payPeriod
        self.hasSeenPaydayNotice = hasSeenPaydayNotice
    }

    public static let `default` = AppSettings()
}
