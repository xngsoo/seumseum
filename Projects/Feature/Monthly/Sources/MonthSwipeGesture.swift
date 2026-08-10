import SwiftUI

/// 가로 스와이프로 월을 옮긴다.
/// Daily 의 날짜 스와이프와 같은 판정을 쓰지만, Feature 끼리 의존하지 않으므로 따로 둔다.
struct MonthSwipeGesture {
    let onPrevious: () -> Void
    let onNext: () -> Void

    var gesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                let horizontal = value.translation.width
                guard abs(horizontal) > abs(value.translation.height) * 1.5 else { return }
                if horizontal < 0 { onNext() } else { onPrevious() }
            }
    }
}
