import Foundation
import Observation
import Domain
import Shared

@MainActor
@Observable
public final class SettingsViewModel {

    public static let defaultDay: PaydayDay = .day(25)

    public private(set) var isPaydayEnabled = false
    public private(set) var paydayDay: PaydayDay = defaultDay
    public private(set) var adjustment: PaydayAdjustment = .prevBusinessDay
    public private(set) var errorMessage: String?

    /// 급여일을 처음 켤 때만 뜨는 안내
    public var isNoticePresented = false

    private var hasSeenNotice = false
    private let settingsRepository: any SettingsRepository

    public init(settingsRepository: any SettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    /// 지금 설정으로 계산한 이번 주기. `7/25 – 8/24`
    public var previewPeriodText: String {
        let period = PayPeriodCalculator.period(containing: CalendarDay.today(), setting: currentSetting)
        return "\(CalendarDay.shortText(period.start)) – \(CalendarDay.shortText(period.lastDay))"
    }

    /// 급여일 행 아래 캡션. `매월 25일 → 7/25 – 8/24`
    public var previewCaption: String {
        isPaydayEnabled
            ? "매월 \(paydayDay.title) → \(previewPeriodText)"
            : "통계를 달력상의 월(1일~말일) 기준으로 봅니다"
    }

    private var currentSetting: PayPeriodSetting {
        isPaydayEnabled ? .payday(day: paydayDay, adjustment: adjustment) : .calendarMonth
    }

    public func load() async {
        do {
            let settings = try await settingsRepository.settings()
            hasSeenNotice = settings.hasSeenPaydayNotice
            switch settings.payPeriod {
            case .calendarMonth:
                isPaydayEnabled = false
            case let .payday(day, rule):
                isPaydayEnabled = true
                paydayDay = day
                adjustment = rule
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func setPaydayEnabled(_ enabled: Bool) async {
        isPaydayEnabled = enabled
        if enabled, !hasSeenNotice {
            isNoticePresented = true
            hasSeenNotice = true
        }
        await save()
    }

    public func setPaydayDay(_ day: PaydayDay) async {
        paydayDay = day
        await save()
    }

    public func setAdjustment(_ rule: PaydayAdjustment) async {
        adjustment = rule
        await save()
    }

    private func save() async {
        do {
            try await settingsRepository.update(
                AppSettings(payPeriod: currentSetting, hasSeenPaydayNotice: hasSeenNotice)
            )
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

public extension PaydayDay {
    /// 피커와 캡션에 쓰는 이름
    var title: String {
        switch self {
        case let .day(value): "\(value)일"
        case .lastDay: "말일"
        }
    }

    /// 피커에 나열하는 순서. 숫자 다음에 말일을 둔다.
    static var pickerOptions: [PaydayDay] {
        range.map { PaydayDay.day($0) } + [.lastDay]
    }
}

public extension PaydayAdjustment {
    var title: String {
        switch self {
        case .prevBusinessDay: "이전 영업일"
        case .nextBusinessDay: "다음 영업일"
        case .none: "그대로"
        }
    }
}
