import SwiftUI

/// 가로 스와이프로 날짜를 옮긴다. List 행 스와이프와 겹치지 않도록
/// 리스트가 아닌 영역(헤더·빈 상태)에만 붙인다.
struct DaySwipeGesture {
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
