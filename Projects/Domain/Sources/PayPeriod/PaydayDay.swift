import Foundation

/// 급여일로 고른 날. `말일`은 달마다 실제 일자가 달라지므로 숫자와 구분한다.
///
/// `.day(31)` 과 `.lastDay` 는 결과가 같아 보이지만 뜻이 다르다.
/// 전자는 "31일, 없으면 그 달 마지막 날로 보정", 후자는 "언제나 그 달 마지막 날"이다.
public enum PaydayDay: Hashable, Sendable {
    case day(Int)
    case lastDay

    public static let range = 1 ... 31

    /// 그 달에서 실제로 며칠인지. 없는 날짜는 그 달 마지막 날로 보정한다.
    public func resolved(daysInMonth: Int) -> Int {
        switch self {
        case let .day(value): min(max(value, Self.range.lowerBound), daysInMonth)
        case .lastDay: daysInMonth
        }
    }
}
