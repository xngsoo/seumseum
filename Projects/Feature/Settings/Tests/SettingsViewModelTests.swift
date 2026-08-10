import Foundation
import Testing
import Shared
import Domain
@testable import Settings

@MainActor
@Suite("SettingsViewModel")
struct SettingsViewModelTests {

    @Test("처음에는 달력 기준이고 안내 문구를 보여준다")
    func defaultState() async {
        let viewModel = SettingsViewModel(settingsRepository: MemorySettingsRepository(), dataResetting: SpyResetter())
        await viewModel.load()

        #expect(!viewModel.isPaydayEnabled)
        #expect(viewModel.previewCaption == "통계를 달력상의 월(1일~말일) 기준으로 봅니다")
    }

    @Test("급여일을 켜면 저장되고 미리보기가 바뀐다")
    func enable() async {
        let repository = MemorySettingsRepository()
        let viewModel = SettingsViewModel(settingsRepository: repository, dataResetting: SpyResetter())
        await viewModel.load()

        await viewModel.setPaydayEnabled(true)
        await viewModel.setPaydayDay(.day(25))

        #expect(viewModel.isPaydayEnabled)
        #expect(viewModel.previewCaption.hasPrefix("매월 25일 → "))
        let saved = await repository.stored.payPeriod
        #expect(saved == .payday(day: .day(25), adjustment: .prevBusinessDay))
    }

    @Test("안내는 처음 켤 때 한 번만 뜬다")
    func noticeOnce() async {
        let repository = MemorySettingsRepository()
        let first = SettingsViewModel(settingsRepository: repository, dataResetting: SpyResetter())
        await first.load()

        await first.setPaydayEnabled(true)
        #expect(first.isNoticePresented, "처음 켜면 안내가 뜬다")
        first.isNoticePresented = false   // 사용자가 안내를 닫는다

        await first.setPaydayEnabled(false)
        await first.setPaydayEnabled(true)
        #expect(!first.isNoticePresented, "같은 화면에서 다시 켜도 뜨지 않는다")

        let second = SettingsViewModel(settingsRepository: repository, dataResetting: SpyResetter())
        await second.load()
        await second.setPaydayEnabled(true)
        #expect(!second.isNoticePresented, "앱을 다시 켜도 뜨지 않는다")
    }

    @Test("급여일을 끄면 달력 기준으로 돌아간다")
    func disable() async {
        let repository = MemorySettingsRepository()
        let viewModel = SettingsViewModel(settingsRepository: repository, dataResetting: SpyResetter())
        await viewModel.load()

        await viewModel.setPaydayEnabled(true)
        await viewModel.setPaydayEnabled(false)

        let saved = await repository.stored.payPeriod
        #expect(saved == .calendarMonth)
    }

    @Test("말일을 고르면 저장되고 캡션에 말일로 표시된다")
    func lastDay() async {
        let repository = MemorySettingsRepository()
        let viewModel = SettingsViewModel(settingsRepository: repository, dataResetting: SpyResetter())
        await viewModel.load()
        await viewModel.setPaydayEnabled(true)

        await viewModel.setPaydayDay(.lastDay)

        #expect(viewModel.previewCaption.hasPrefix("매월 말일 → "))
        let saved = await repository.stored.payPeriod
        #expect(saved == .payday(day: .lastDay, adjustment: .prevBusinessDay))
    }

    @Test("피커 항목은 1…31 다음에 말일이다")
    func pickerOptions() {
        let options = PaydayDay.pickerOptions
        #expect(options.count == 32)
        #expect(options.first == .day(1))
        #expect(options.last == .lastDay)
        #expect(PaydayDay.day(3).title == "3일")
        #expect(PaydayDay.lastDay.title == "말일")
    }

    @Test("보정 규칙을 바꾸면 저장된다")
    func adjustment() async {
        let repository = MemorySettingsRepository()
        let viewModel = SettingsViewModel(settingsRepository: repository, dataResetting: SpyResetter())
        await viewModel.load()
        await viewModel.setPaydayEnabled(true)

        await viewModel.setAdjustment(.nextBusinessDay)

        let saved = await repository.stored.payPeriod
        #expect(saved == .payday(day: SettingsViewModel.defaultDay, adjustment: .nextBusinessDay))
    }

    @Test("저장된 설정을 다시 읽어 화면에 채운다")
    func restore() async {
        let repository = MemorySettingsRepository()
        try? await repository.update(
            AppSettings(payPeriod: .payday(day: .day(10), adjustment: .none), hasSeenPaydayNotice: true)
        )

        let viewModel = SettingsViewModel(settingsRepository: repository, dataResetting: SpyResetter())
        await viewModel.load()

        #expect(viewModel.isPaydayEnabled)
        #expect(viewModel.paydayDay == .day(10))
        #expect(viewModel.adjustment == .none)
    }
}

@Suite("데이터 초기화")
@MainActor
struct DataResetTests {

    @Test("초기화하면 지출만 지우고 완료 알림을 띄운다")
    func reset() async {
        let resetter = SpyResetter()
        let viewModel = SettingsViewModel(
            settingsRepository: MemorySettingsRepository(), dataResetting: resetter
        )

        await viewModel.resetAllExpenses()

        #expect(await resetter.callCount == 1)
        #expect(viewModel.isResetDonePresented)
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.isResetting)
    }

    @Test("초기화가 실패하면 알리고 완료 알림은 띄우지 않는다")
    func resetFailure() async {
        let viewModel = SettingsViewModel(
            settingsRepository: MemorySettingsRepository(),
            dataResetting: SpyResetter(failure: .storageFailed("실패"))
        )

        await viewModel.resetAllExpenses()

        #expect(!viewModel.isResetDonePresented)
        #expect(viewModel.errorMessage != nil)
    }

    @Test("설정은 초기화 대상이 아니다")
    func keepsSettings() async {
        let repository = MemorySettingsRepository()
        let viewModel = SettingsViewModel(
            settingsRepository: repository, dataResetting: SpyResetter()
        )
        await viewModel.load()
        await viewModel.setPaydayEnabled(true)
        await viewModel.setPaydayDay(.lastDay)

        await viewModel.resetAllExpenses()

        let saved = await repository.stored.payPeriod
        #expect(saved == .payday(day: .lastDay, adjustment: .prevBusinessDay))
    }
}

private actor SpyResetter: DataResetting {
    private(set) var callCount = 0
    private let failure: DomainError?

    init(failure: DomainError? = nil) { self.failure = failure }

    func deleteAllExpenses() async throws {
        callCount += 1
        if let failure { throw failure }
    }
}

private actor MemorySettingsRepository: SettingsRepository {
    private(set) var stored = AppSettings()

    func settings() async throws -> AppSettings { stored }
    func update(_ settings: AppSettings) async throws { stored = settings }
}
