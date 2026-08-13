import SwiftUI
import UIKit
import Shared

/// 테마 하나가 만들어 내는 색 묶음.
///
/// 디자인은 모든 색을 색상각 하나에서 뽑아낸다. 그래서 네 벌을 카탈로그에 구워 두는
/// 대신 여기서 계산한다. 테마가 늘어도 `AppTheme` 에 각도만 더하면 된다.
/// 카테고리 색처럼 테마와 무관한 색은 그대로 에셋 카탈로그에 둔다.
struct ThemePalette {
    let theme: AppTheme

    private var hue: Double { theme.hue }

    // MARK: - 바탕과 표면

    /// 면은 밝은 화면에서도 테마의 기운을 옅게 머금는다.
    /// 특히 가라앉은 면은 넓게 깔려서, 고정된 색을 쓰면 테마를 바꿨을 때 혼자 겉돈다.
    var background: Color {
        dynamic(light: oklch(0.971, 0.004), dark: oklch(0.185, 0.012))
    }

    /// 흰 면만은 어느 테마에서도 희다. 카드가 바탕에서 또렷하게 떠오르게 하기 위함이다.
    var surface: Color { dynamic(light: hex(0xFFFFFF), dark: oklch(0.235, 0.014)) }
    var surfaceRaised: Color { dynamic(light: oklch(0.986, 0.003), dark: oklch(0.26, 0.014)) }
    var surfaceSunken: Color { dynamic(light: oklch(0.928, 0.011), dark: oklch(0.22, 0.012)) }

    // MARK: - 글자

    var textPrimary: Color { dynamic(light: hex(0x1B1A17), dark: oklch(0.95, 0.006)) }
    var textStrong: Color { dynamic(light: hex(0x4A4842), dark: oklch(0.85, 0.008)) }
    var textSecondary: Color { dynamic(light: hex(0x6F6C65), dark: oklch(0.76, 0.008)) }
    var textMuted: Color { dynamic(light: hex(0x8B8880), dark: oklch(0.66, 0.008)) }
    var textFaint: Color { dynamic(light: hex(0xA5A29A), dark: oklch(0.58, 0.008)) }
    var textDim: Color { dynamic(light: hex(0xC9C6BF), dark: oklch(0.44, 0.008)) }

    // MARK: - 액센트

    var accent: Color { dynamic(light: oklch(0.62, 0.13), dark: oklch(0.74, 0.13)) }
    var accentDeep: Color { dynamic(light: oklch(0.54, 0.13), dark: oklch(0.68, 0.13)) }
    var accentInk: Color { dynamic(light: oklch(0.52, 0.13), dark: oklch(0.80, 0.12)) }
    var accentSoft: Color { dynamic(light: oklch(0.95, 0.035), dark: oklch(0.31, 0.055)) }
    var accentUndo: Color { dynamic(light: oklch(0.80, 0.11), dark: oklch(0.62, 0.13)) }

    // MARK: - 스낵바

    /// 스낵바는 바탕과 반대로 간다. 밝은 화면에서 어둡고, 어두운 화면에서 밝다.
    var snackbarSurface: Color { dynamic(light: hex(0x26241F), dark: oklch(0.90, 0.010)) }
    var snackbarLabel: Color { dynamic(light: hex(0xF2F0EA), dark: oklch(0.20, 0.010)) }

    // MARK: - 계산

    /// 밝고 어두운 화면을 한 색으로 묶는다. 시스템이 상황에 맞는 쪽을 골라 준다.
    private func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    private func hex(_ value: UInt32) -> UIColor {
        UIColor(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }

    private func oklch(_ lightness: Double, _ chroma: Double) -> UIColor {
        OKLCH.color(lightness: lightness, chroma: chroma, hue: hue)
    }
}

/// OKLCH → sRGB 변환.
///
/// 밝기가 고르게 나뉘는 색 공간이라, 같은 L 값이면 색상각이 달라도 비슷한 밝기로 보인다.
/// 디자인이 이 공간으로 팔레트를 정의해서 계산식을 그대로 옮겼다.
enum OKLCH {

    static func color(lightness: Double, chroma: Double, hue: Double) -> UIColor {
        let radians = hue * .pi / 180
        let aAxis = chroma * cos(radians)
        let bAxis = chroma * sin(radians)

        // 원뿔 세포 반응으로 옮겼다가 세제곱해 되돌린다.
        let long = pow(lightness + 0.3963377774 * aAxis + 0.2158037573 * bAxis, 3)
        let medium = pow(lightness - 0.1055613458 * aAxis - 0.0638541728 * bAxis, 3)
        let short = pow(lightness - 0.0894841775 * aAxis - 1.2914855480 * bAxis, 3)

        return UIColor(
            red: encode(4.0767416621 * long - 3.3077115913 * medium + 0.2309699292 * short),
            green: encode(-1.2684380046 * long + 2.6097574011 * medium - 0.3413193965 * short),
            blue: encode(-0.0041960863 * long - 0.7034186147 * medium + 1.7076147010 * short),
            alpha: 1
        )
    }

    /// 선형 값에 감마를 씌워 화면에 쓰는 값으로 바꾼다. 표현할 수 없는 색은 잘라 낸다.
    private static func encode(_ value: Double) -> CGFloat {
        let clamped = min(max(value, 0), 1)
        let encoded = clamped > 0.0031308
            ? 1.055 * pow(clamped, 1 / 2.4) - 0.055
            : 12.92 * clamped
        return CGFloat(min(max(encoded, 0), 1))
    }
}
