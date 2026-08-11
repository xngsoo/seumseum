import Foundation

/// 카테고리 색 팔레트의 식별자. 실제 색값은 DesignSystem이 정한다.
/// 나열 순서가 색상 선택 격자의 순서다. 색상환을 따라 두고 무채색을 뒤에 붙였다.
public enum ColorToken: String, CaseIterable, Sendable {
    case red, orange, yellow, lime, green, teal
    case blue, indigo, purple, pink, brown, gray
}
