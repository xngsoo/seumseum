import CoreGraphics

public enum AppSpacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 24
    public static let screenMargin: CGFloat = 22
    public static let cornerRadius: CGFloat = 13
    /// 카드처럼 넓은 면의 모서리.
    public static let cardRadius: CGFloat = 14

    // MARK: - 떠 있는 탭바

    public static let tabBarHeight: CGFloat = 60
    /// 탭바가 화면 좌우에서 떨어지는 거리.
    public static let tabBarInset: CGFloat = 14
    /// 탭바를 안전 영역 위로 더 띄우는 여백.
    /// 디자인의 30pt 중 나머지는 홈 인디케이터의 안전 영역이 채운다.
    public static let tabBarBottom: CGFloat = 6
    /// 탭바 뒤로 내용이 지나가도록 스크롤 아래에 두는 여백.
    public static let scrollBottomInset: CGFloat = 132
    /// 탭바를 가리며 올라오는 하단 그라데이션의 높이.
    public static let bottomFadeHeight: CGFloat = 96
}
