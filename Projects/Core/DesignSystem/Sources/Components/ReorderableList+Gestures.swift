import SwiftUI

// ReorderableList 의 제스처와 자동 스크롤.
// 본체와 나눠 두어야 한 파일·한 타입이 지나치게 길어지지 않는다.
extension ReorderableList {

    // MARK: - 탭

    func tap(_ item: Item) {
        if swipedID == nil {
            onSelect(item)
        } else {
            closeSwipe()
        }
    }

    // MARK: - 롱프레스 드래그 재정렬

    /// 좌표계가 `.global` 인 것이 중요하다. 기본값인 `.local` 은 행 자신의 좌표계라서
    /// 자리가 바뀌거나 `offset` 이 걸리면 손가락이 멈춰 있어도 `translation` 이 튄다.
    /// 그 값으로 다시 목표 자리를 정하면 되먹임이 생겨 행이 두 자리를 오간다.
    func reorderGesture(_ item: Item) -> some Gesture {
        LongPressGesture(minimumDuration: 0.35)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .global))
            .onChanged { value in
                guard case let .second(_, drag) = value else { return }
                if draggingID != item.id {
                    closeSwipe()
                    draggingID = item.id
                    dragStartIndex = items.firstIndex { $0.id == item.id }
                    dragTranslation = 0
                    autoScrollShift = 0
                }
                guard let drag else { return }
                dragTranslation = drag.translation.height
                dragScreenY = drag.location.y
                reorderIfNeeded(item)
            }
            .onEnded { _ in endReorder() }
    }

    /// 목표 자리는 항상 "시작 자리 + 총 이동량 ÷ 행 높이" 로 구한다.
    /// 한 칸 옮길 때마다 이동량을 깎는 방식은 다음 이벤트가 원래 이동량으로 덮어써서
    /// 같은 손짓에 여러 칸이 계속 밀린다.
    func reorderIfNeeded(_ item: Item) {
        guard let start = dragStartIndex,
              let current = items.firstIndex(where: { $0.id == item.id }) else { return }

        let shift = Int((travelled / rowHeight).rounded())
        let target = min(max(start + shift, 0), items.count - 1)
        guard target != current else { return }

        onMove(current, target)
    }

    /// 손가락이 끈 거리에 자동 스크롤로 흘러간 거리를 더한 값.
    var travelled: CGFloat {
        dragTranslation + autoScrollShift
    }

    /// 들고 있는 행은 이미 옮겨간 칸수만큼 빼야 손가락 아래에 그대로 붙어 있는다.
    func dragOffset(of item: Item) -> CGFloat {
        guard item.id == draggingID,
              let start = dragStartIndex,
              let current = items.firstIndex(where: { $0.id == item.id }) else { return 0 }
        return travelled - CGFloat(current - start) * rowHeight
    }

    func endReorder() {
        guard draggingID != nil else { return }
        stopAutoScroll()
        withAnimation(.snappy(duration: 0.2)) {
            draggingID = nil
            dragStartIndex = nil
            dragTranslation = 0
            autoScrollShift = 0
        }
        onMoveEnded()
    }

    func moveByAccessibility(from source: Int, to destination: Int) {
        withAnimation(.snappy(duration: 0.2)) {
            onMove(source, destination)
        }
        onMoveEnded()
    }

    // MARK: - 가장자리 자동 스크롤

    func updateAutoScroll(in viewport: CGRect) {
        guard draggingID != nil else {
            stopAutoScroll()
            return
        }

        if dragScreenY < viewport.minY + edgeZone {
            autoScrollDirection = -1
        } else if dragScreenY > viewport.maxY - edgeZone {
            autoScrollDirection = 1
        } else {
            stopAutoScroll()
            return
        }
        startAutoScroll()
    }

    /// 손가락이 멈춰 있어도 계속 흘러야 하므로 박자만 반복 작업으로 만든다.
    ///
    /// 실제 일감을 이 안에서 하면 안 된다. `ReorderableList` 는 구조체라
    /// 작업이 붙든 `items` 는 시작 시점의 사본에 머문다. 그 낡은 배열로 자리를 계산하면
    /// 매 박자마다 엉뚱한 행이 옮겨져 목록이 뒤섞인다.
    /// 그래서 여기서는 `autoScrollTick` 만 올리고, 실제 이동은 뷰가 최신 `items` 로 처리한다.
    func startAutoScroll() {
        guard autoScrollTask == nil else { return }
        autoScrollTask = Task { @MainActor in
            while !Task.isCancelled, autoScrollDirection != 0, draggingID != nil {
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled else { break }
                autoScrollTick += 1
            }
            autoScrollTask = nil
        }
    }

    /// 박자마다 한 칸씩 흘리고, 그만큼 손가락이 더 끈 것으로 쳐서 자리도 한 칸 옮긴다.
    func autoScrollStep(_ scroller: ScrollViewProxy) {
        guard autoScrollDirection != 0,
              let draggingID,
              let current = items.firstIndex(where: { $0.id == draggingID }) else { return }

        let neighbour = current + autoScrollDirection
        guard items.indices.contains(neighbour) else {
            // 끝에 닿았으면 더 흐를 곳이 없다.
            stopAutoScroll()
            return
        }

        withAnimation(.linear(duration: 0.15)) {
            scroller.scrollTo(items[neighbour].id, anchor: autoScrollDirection < 0 ? .top : .bottom)
        }
        autoScrollShift += CGFloat(autoScrollDirection) * rowHeight
        reorderIfNeeded(items[current])
    }

    func stopAutoScroll() {
        autoScrollDirection = 0
        autoScrollTask?.cancel()
        autoScrollTask = nil
    }

    // MARK: - 스와이프 삭제

    /// 스와이프도 같은 이유로 `.global` 이다. 행이 왼쪽으로 밀린 만큼 로컬 좌표가 따라 움직여서
    /// 기본 좌표계로는 이동량이 깎인다.
    func swipeGesture(_ item: Item) -> some Gesture {
        DragGesture(minimumDistance: 12, coordinateSpace: .global)
            .onChanged { value in
                guard onDelete != nil, draggingID == nil else { return }
                // 세로로 끄는 손짓은 스크롤에 넘긴다.
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                if swipedID != item.id {
                    swipedID = item.id
                    swipeBase = 0
                }
                swipeOffset = min(max(swipeBase + value.translation.width, -deleteWidth * 1.2), 0)
            }
            .onEnded { _ in
                guard swipedID == item.id else { return }
                let opens = swipeOffset < -deleteWidth / 2
                swipeBase = opens ? -deleteWidth : 0
                withAnimation(.snappy(duration: 0.2)) {
                    swipeOffset = swipeBase
                    if !opens { swipedID = nil }
                }
            }
    }

    func closeSwipe() {
        guard swipedID != nil else { return }
        swipeBase = 0
        withAnimation(.snappy(duration: 0.2)) {
            swipeOffset = 0
            swipedID = nil
        }
    }
}
