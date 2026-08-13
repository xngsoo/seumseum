import SwiftUI

/// 가로 스와이프로 날짜를 옮긴다.
///
/// 화면 전체에 붙어 세로 스크롤과 함께 인식되므로, 움직이기 시작할 때 방향을 한 번
/// 정하고 그대로 잠근다. 잠그지 않으면 가로로 끄는 동안 목록이 세로로도 함께
/// 스크롤되어 화면이 대각선으로 끌려간다.
///
/// 끄는 동안 손가락을 그대로 따라가지 않고 눌러서 따라간다.
/// 화면이 통째로 끌려다니면 목록을 읽는 데 방해가 된다.
@MainActor
struct DaySwipeGesture {

    /// 이번 끌기가 어느 쪽으로 정해졌는지.
    enum Direction {
        /// 아직 방향을 정하기에 이르다.
        case undecided
        /// 날짜를 넘기는 중. 세로 스크롤을 멈춘다.
        case horizontal
        /// 목록을 읽는 중. 날짜는 건드리지 않는다.
        case vertical
    }

    /// 손을 떼기 전까지 화면이 따라 움직인 거리.
    @Binding var offset: CGFloat
    @Binding var direction: Direction
    let onPrevious: () -> Void
    let onNext: () -> Void

    /// 이만큼 끌어야 날짜가 넘어간다.
    private let threshold: CGFloat = 60
    /// 따라 움직이는 비율.
    private let damping: CGFloat = 0
    /// 이만큼 움직이면 방향을 정한다. 스크롤이 시작되기 전에 판정해야 한다.
    private let decisionDistance: CGFloat = 10

    var gesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                decideDirection(value.translation)
                guard direction == .horizontal else { return }
                offset = value.translation.width * damping
            }
            .onEnded { value in
                let wasHorizontal = direction == .horizontal
                direction = .undecided
                let horizontal = value.translation.width

                guard wasHorizontal, abs(horizontal) > threshold else {
                    withAnimation(.spring(duration: 0.3)) { offset = 0 }
                    return
                }
                // 새 날짜가 자기 자리에서 들어오도록 먼저 되돌린다.
                offset = 0
                if horizontal < 0 { onNext() } else { onPrevious() }
            }
    }

    /// 한 번 정한 방향은 손을 뗄 때까지 바꾸지 않는다.
    private func decideDirection(_ translation: CGSize) {
        guard direction == .undecided else { return }
        let width = abs(translation.width)
        let height = abs(translation.height)
        guard max(width, height) > decisionDistance else { return }
        direction = width > height ? .horizontal : .vertical
    }
}
