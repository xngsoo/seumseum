import Foundation

/// 아직 내보내지 않은 기능을 화면에서만 감춘다. 저장 구조와 로직은 그대로 두고 진입점만 막는다.
public enum FeatureFlag {
    /// 정액 품목 분리. 보류 중이라 설정의 진입점과 추가 화면의 입력을 함께 감춘다.
    /// 되살릴 때는 이 값만 `true` 로 바꾸면 된다.
    public static let splitItem = false
}
