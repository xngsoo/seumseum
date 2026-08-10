import Foundation
import Testing
import Domain
@testable import Persistence

@Suite("SettingsRepository")
struct SettingsRepositoryTests {

    /// 테스트마다 별도 suite 를 써서 실제 사용자 설정과 서로를 오염시키지 않는다.
    private func makeDefaults() throws -> UserDefaults {
        let name = "test.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test("기본값은 달력상의 월이다")
    func defaultSetting() async throws {
        let repository = UserDefaultsSettingsRepository(defaults: try makeDefaults())
        #expect(try await repository.settings().payPeriod == .calendarMonth)
    }

    @Test("급여일 설정을 저장하고 다시 읽는다")
    func roundTrip() async throws {
        let repository = UserDefaultsSettingsRepository(defaults: try makeDefaults())
        let setting = AppSettings(payPeriod: .payday(day: .day(25), adjustment: .nextBusinessDay))

        try await repository.update(setting)

        #expect(try await repository.settings() == setting)
    }

    @Test("급여일을 껐다가 다시 읽으면 달력상의 월이다")
    func disable() async throws {
        let repository = UserDefaultsSettingsRepository(defaults: try makeDefaults())
        try await repository.update(AppSettings(payPeriod: .payday(day: .day(10), adjustment: .none)))
        try await repository.update(AppSettings(payPeriod: .calendarMonth))

        #expect(try await repository.settings().payPeriod == .calendarMonth)
    }

    @Test("알 수 없는 보정 규칙이 저장돼 있으면 기본값으로 읽는다")
    func unknownAdjustment() async throws {
        let defaults = try makeDefaults()
        defaults.set(true, forKey: "settings.payday.enabled")
        defaults.set(25, forKey: "settings.payday.dayOfMonth")
        defaults.set("깨진값", forKey: "settings.payday.adjustment")

        let repository = UserDefaultsSettingsRepository(defaults: defaults)
        #expect(
            try await repository.settings().payPeriod
                == .payday(day: .day(25), adjustment: .prevBusinessDay)
        )
    }
}
