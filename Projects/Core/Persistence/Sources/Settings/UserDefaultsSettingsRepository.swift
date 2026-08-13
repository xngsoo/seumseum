import Foundation
import Domain
import Shared

/// 설정은 양이 적고 관계가 없어 SwiftData 대신 UserDefaults 에 둔다.
/// 열거형을 통째로 인코딩하지 않고 원시 값으로 나눠 저장해, 케이스가 늘어도 마이그레이션이 쉽다.
public final class UserDefaultsSettingsRepository: SettingsRepository, @unchecked Sendable {

    private enum Key {
        static let paydayEnabled = "settings.payday.enabled"
        static let paydayDayOfMonth = "settings.payday.dayOfMonth"
        static let paydayAdjustment = "settings.payday.adjustment"
        static let paydayNoticeSeen = "settings.payday.noticeSeen"
        static let splitEnabled = "settings.split.enabled"
        static let splitName = "settings.split.name"
        static let splitUnitAmount = "settings.split.unitAmount"
        static let splitCategoryID = "settings.split.categoryID"
        static let splitUnitLabel = "settings.split.unitLabel"
        static let theme = "settings.appearance.theme"
        static let darkMode = "settings.appearance.darkMode"
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
        let split = storedSplitItem()
        let theme = AppTheme(rawValue: defaults.string(forKey: Key.theme) ?? "") ?? .default
        let isDarkMode = defaults.bool(forKey: Key.darkMode)
        guard defaults.bool(forKey: Key.paydayEnabled) else {
            return AppSettings(
                payPeriod: .calendarMonth, hasSeenPaydayNotice: noticeSeen, splitItem: split,
                theme: theme, isDarkMode: isDarkMode
            )
        }
        // 0 은 말일을 뜻한다. 실제 일자는 1…31 이라 겹치지 않는다.
        let stored = defaults.integer(forKey: Key.paydayDayOfMonth)
        let day: PaydayDay = stored == Self.lastDaySentinel ? .lastDay : .day(stored)
        let raw = defaults.string(forKey: Key.paydayAdjustment) ?? ""
        // PaydayAdjustment 에 none 케이스가 있어 Optional.none 과 헷갈린다. 타입을 명시한다.
        let adjustment = PaydayAdjustment(rawValue: raw) ?? PaydayAdjustment.prevBusinessDay
        return AppSettings(
            payPeriod: .payday(day: day, adjustment: adjustment),
            hasSeenPaydayNotice: noticeSeen,
            splitItem: split,
            theme: theme,
            isDarkMode: isDarkMode
        )
    }

    /// 금액은 Decimal 정밀도를 잃지 않도록 문자열로 저장한다.
    private func storedSplitItem() -> SplitItem? {
        guard defaults.bool(forKey: Key.splitEnabled),
              let name = defaults.string(forKey: Key.splitName),
              let rawAmount = defaults.string(forKey: Key.splitUnitAmount),
              let amount = Decimal(string: rawAmount),
              let rawID = defaults.string(forKey: Key.splitCategoryID),
              let categoryID = UUID(uuidString: rawID)
        else { return nil }
        return SplitItem(
            name: name,
            unitAmount: amount,
            categoryID: categoryID,
            unitLabel: defaults.string(forKey: Key.splitUnitLabel) ?? "개"
        )
    }

    public func update(_ settings: AppSettings) async throws {
        defaults.set(settings.hasSeenPaydayNotice, forKey: Key.paydayNoticeSeen)
        defaults.set(settings.theme.rawValue, forKey: Key.theme)
        defaults.set(settings.isDarkMode, forKey: Key.darkMode)
        if let split = settings.splitItem {
            defaults.set(true, forKey: Key.splitEnabled)
            defaults.set(split.name, forKey: Key.splitName)
            defaults.set("\(split.unitAmount)", forKey: Key.splitUnitAmount)
            defaults.set(split.categoryID.uuidString, forKey: Key.splitCategoryID)
            defaults.set(split.unitLabel, forKey: Key.splitUnitLabel)
        } else {
            defaults.set(false, forKey: Key.splitEnabled)
        }
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
