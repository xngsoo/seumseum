import SwiftUI

/// 가로 스와이프로 주기를 옮긴다.
struct PeriodSwipeGesture {
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
