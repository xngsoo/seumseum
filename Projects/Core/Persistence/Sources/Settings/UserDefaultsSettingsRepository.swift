import Foundation
import Domain

/// 설정은 양이 적고 관계가 없어 SwiftData 대신 UserDefaults 에 둔다.
/// 열거형을 통째로 인코딩하지 않고 원시 값으로 나눠 저장해, 케이스가 늘어도 마이그레이션이 쉽다.
public final class UserDefaultsSettingsRepository: SettingsRepository, @unchecked Sendable {

    private enum Key {
        static let paydayEnabled = "settings.payday.enabled"
        static let paydayDayOfMonth = "settings.payday.dayOfMonth"
        static let paydayAdjustment = "settings.payday.adjustment"
        static let paydayNoticeSeen = "settings.payday.noticeSeen"
    }

    /// 저장 포맷에서 말일을 나타내는 값
    private static let lastDaySentinel = 0

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func settings() async throws -> AppSettings {
        // 급여일 on/off 와 무관하게 저장·복원해야 껐다 켜도 안내가 다시 뜨지 않는다.
        let noticeSeen = defaults.bool(forKey: Key.paydayNoticeSeen)
        guard defaults.bool(forKey: Key.paydayEnabled) else {
            return AppSettings(payPeriod: .calendarMonth, hasSeenPaydayNotice: noticeSeen)
        }
        // 0 은 말일을 뜻한다. 실제 일자는 1…31 이라 겹치지 않는다.
        let stored = defaults.integer(forKey: Key.paydayDayOfMonth)
        let day: PaydayDay = stored == Self.lastDaySentinel ? .lastDay : .day(stored)
        let raw = defaults.string(forKey: Key.paydayAdjustment) ?? ""
        // PaydayAdjustment 에 none 케이스가 있어 Optional.none 과 헷갈린다. 타입을 명시한다.
        let adjustment = PaydayAdjustment(rawValue: raw) ?? PaydayAdjustment.prevBusinessDay
        return AppSettings(
            payPeriod: .payday(day: day, adjustment: adjustment),
            hasSeenPaydayNotice: noticeSeen
        )
    }

    public func update(_ settings: AppSettings) async throws {
        defaults.set(settings.hasSeenPaydayNotice, forKey: Key.paydayNoticeSeen)
        switch settings.payPeriod {
        case .calendarMonth:
            defaults.set(false, forKey: Key.paydayEnabled)
        case let .payday(day, adjustment):
            defaults.set(true, forKey: Key.paydayEnabled)
            switch day {
            case let .day(value): defaults.set(value, forKey: Key.paydayDayOfMonth)
            case .lastDay: defaults.set(Self.lastDaySentinel, forKey: Key.paydayDayOfMonth)
            }
            defaults.set(adjustment.rawValue, forKey: Key.paydayAdjustment)
        }
    }
}
