import Foundation

/// 기록 전체를 지우는 기능. 되돌릴 수 없어 일반 저장소 프로토콜과 분리해 둔다.
/// 별도 타입으로 두면 실수로 호출할 표면이 좁아지고, 기존 저장소 구현이 영향을 받지 않는다.
public protocol DataResetting: Sendable {
    /// 모든 지출 기록을 지운다. 카테고리와 설정은 남는다.
    func deleteAllExpenses() async throws
}
