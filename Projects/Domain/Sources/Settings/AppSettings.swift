import Foundation

/// 사용자 설정. 지금은 급여 주기만 담고, 탭 4가 붙으면서 확장된다.
public struct AppSettings: Hashable, Sendable {
    public var payPeriod: PayPeriodSetting

    public init(payPeriod: PayPeriodSetting = .calendarMonth) {
        self.payPeriod = payPeriod
    }

    public static let `default` = AppSettings()
}
