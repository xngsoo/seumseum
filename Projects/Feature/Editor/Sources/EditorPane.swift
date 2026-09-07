import Foundation

/// 화면 아래 절반을 나눠 쓰는 입력 판.
///
/// 셋을 세로로 늘어놓으면 작은 기기에서 스크롤이 생기고, 금액을 다 넣은 뒤에도
/// 키패드가 자리를 차지한다. 한 자리를 번갈아 쓰면 손가락이 화면 아래에 머문 채
/// 금액 → 카테고리 → 날짜까지 끝난다.
enum EditorPane: CaseIterable {
    case amount
    case category
    case detail

    var title: String {
        switch self {
        case .amount: "금액"
        case .category: "카테고리"
        case .detail: "날짜 및 내용"
        }
    }
}
