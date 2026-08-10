import Foundation
import Domain

/// 설정은 양이 적고 관계가 없어 SwiftData 대신 UserDefaults 에 둔다.
/// 열거형을 통째로 인코딩하지 않고 원시 값으로 나눠 저장해, 케이스가 늘어도 마이그레이션이 쉽다.
public final class UserDefaultsSettingsRepository: SettingsRepository, @unchecked Sendable {

    private enum Key {
        static let paydayEnabled = "settings.payday.enabled"
        static let paydayDayOfMonth = "settings.payday.dayOfMonth"
        static let paydayAdjustment = "settings.payday.adjustment"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func settings() async throws -> AppSettings {
        guard defaults.bool(forKey: Key.paydayEnabled) else {
            return AppSettings(payPeriod: .calendarMonth)
        }
        let day = defaults.integer(forKey: Key.paydayDayOfMonth)
        let raw = defaults.string(forKey: Key.paydayAdjustment) ?? ""
        // PaydayAdjustment 에 none 케이스가 있어 Optional.none 과 헷갈린다. 타입을 명시한다.
        let adjustment = PaydayAdjustment(rawValue: raw) ?? PaydayAdjustment.prevBusinessDay
        return AppSettings(payPeriod: .payday(dayOfMonth: day, adjustment: adjustment))
    }

    public func update(_ settings: AppSettings) async throws {
        switch settings.payPeriod {
        case .calendarMonth:
            defaults.set(false, forKey: Key.paydayEnabled)
        case let .payday(dayOfMonth, adjustment):
            defaults.set(true, forKey: Key.paydayEnabled)
            defaults.set(dayOfMonth, forKey: Key.paydayDayOfMonth)
            defaults.set(adjustment.rawValue, forKey: Key.paydayAdjustment)
        }
    }
}
