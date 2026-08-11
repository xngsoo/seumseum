import SwiftUI

/// 롱프레스 드래그 재정렬과 스와이프 삭제를 직접 다루는 목록.
///
/// `List` 를 쓰지 않는 이유는 재정렬 뒤 마지막 행 아래에 구분선이 되살아나고,
/// 행 구성을 다시 적용하는 시점을 우리가 잡을 수 없기 때문이다.
/// 재정렬을 행 높이 단위로 계산하므로 모든 행의 높이는 `rowHeight` 로 같다.
/// 호출부에서 `@ScaledMetric` 으로 넘기면 글자 크기 설정을 따라간다.
public struct ReorderableList<Item: Identifiable, Row: View, Footer: View>: View {

    private let items: [Item]
    private let rowHeight: CGFloat
    private let onSelect: (Item) -> Void
    /// nil 이면 스와이프 삭제를 붙이지 않는다.
    private let onDelete: ((Item) -> Void)?
    /// 드래그하는 동안 화면 순서만 바꾼다.
    private let onMove: (Int, Int) -> Void
    /// 손을 뗄 때 한 번만 저장한다.
    private let onMoveEnded: () -> Void
    private let row: (Item) -> Row
    private let footer: () -> Footer

    @State private var draggingID: Item.ID?
    /// 드래그를 시작한 자리. 목표 위치를 여기서부터 절대 계산한다.
    @State private var dragStartIndex: Int?
    @State private var dragTranslation: CGFloat = 0
    @State private var swipedID: Item.ID?
    @State private var swipeOffset: CGFloat = 0
    @State private var swipeBase: CGFloat = 0

    private let deleteWidth: CGFloat = 88

    public init(
        _ items: [Item],
        rowHeight: CGFloat,
        onSelect: @escaping (Item) -> Void,
        onDelete: ((Item) -> Void)? = nil,
        onMove: @escaping (Int, Int) -> Void,
        onMoveEnded: @escaping () -> Void,
        @ViewBuilder row: @escaping (Item) -> Row,
        @ViewBuilder footer: @escaping () -> Footer
    ) {
        self.items = items
        self.rowHeight = rowHeight
        self.onSelect = onSelect
        self.onDelete = onDelete
        self.onMove = onMove
        self.onMoveEnded = onMoveEnded
        self.row = row
        self.footer = footer
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        rowView(item)
                    }
                }
                // 드래그 중에는 애니메이션을 끈다. 자리 이동이 애니메이션되면
                // 들고 있는 행이 손가락보다 한 칸씩 뒤처진다.
                .animation(draggingID == nil ? .snappy(duration: 0.25) : nil, value: items.map(\.id))

                footer()
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .scrollDisabled(draggingID != nil)
        .sensoryFeedback(.selection, trigger: draggingID)
        .onChange(of: items.map(\.id)) { _, _ in
            if draggingID == nil { closeSwipe() }
        }
    }

    // MARK: - 행

    private func rowView(_ item: Item) -> some View {
        let isDragging = item.id == draggingID
        let isSwiped = item.id == swipedID

        return ZStack(alignment: .trailing) {
            if let onDelete {
                deleteButton(item, onDelete: onDelete)
                    .opacity(isSwiped ? 1 : 0)
                    .accessibilityHidden(!isSwiped)
            }

            row(item)
                .padding(.horizontal, AppSpacing.screenMargin)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: rowHeight)
                .background(AppColor.surface)
                .overlay(alignment: .bottom) {
                    if !isDragging, item.id != items.last?.id {
                        Divider()
                            .overlay(AppColor.separator)
                            .padding(.leading, AppSpacing.screenMargin)
                    }
                }
                .offset(x: isSwiped ? swipeOffset : 0)
        }
        .frame(height: rowHeight)
        .scaleEffect(isDragging ? 1.02 : 1)
        .shadow(color: .black.opacity(isDragging ? 0.18 : 0), radius: 8, y: 4)
        .offset(y: dragOffset(of: item))
        .zIndex(isDragging ? 1 : 0)
        .contentShape(Rectangle())
        .onTapGesture { tap(item) }
        // 둘 다 simultaneous 여야 한다. `gesture` 로 붙이면 스크롤뷰의 팬보다 우선권을 가져서,
        // 행이 화면을 채웠을 때 손가락이 늘 행 위에서 시작하므로 스크롤이 아예 시작되지 않는다.
        .simultaneousGesture(reorderGesture(item))
        .simultaneousGesture(swipeGesture(item))
        .transition(.opacity)
    }

    private func deleteButton(_ item: Item, onDelete: @escaping (Item) -> Void) -> some View {
        Button {
            closeSwipe()
            onDelete(item)
        } label: {
            Text("삭제")
                .font(AppFont.rowTitle)
                .foregroundStyle(.white)
                .frame(width: deleteWidth)
                // 라벨은 오른쪽 88pt 안에 두되 바탕은 행 전체를 덮는다.
                // 바탕을 라벨 폭에만 깔면 행을 88pt 너머로 밀었을 때 그 사이로 배경이 비친다.
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .background(AppColor.category(.red))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("삭제")
    }

    // MARK: - 탭

    private func tap(_ item: Item) {
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
    private func reorderGesture(_ item: Item) -> some Gesture {
        LongPressGesture(minimumDuration: 0.35)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .global))
            .onChanged { value in
                guard case let .second(_, drag) = value else { return }
                if draggingID != item.id {
                    closeSwipe()
                    draggingID = item.id
                    dragStartIndex = items.firstIndex { $0.id == item.id }
                    dragTranslation = 0
                }
                guard let drag else { return }
                dragTranslation = drag.translation.height
                reorderIfNeeded(item)
            }
            .onEnded { _ in endReorder() }
    }

    /// 목표 자리는 항상 "시작 자리 + 총 이동량 ÷ 행 높이" 로 구한다.
    /// 한 칸 옮길 때마다 이동량을 깎는 방식은 다음 이벤트가 원래 이동량으로 덮어써서
    /// 같은 손짓에 여러 칸이 계속 밀린다.
    private func reorderIfNeeded(_ item: Item) {
        guard let start = dragStartIndex,
              let current = items.firstIndex(where: { $0.id == item.id }) else { return }

        let shift = Int((dragTranslation / rowHeight).rounded())
        let target = min(max(start + shift, 0), items.count - 1)
        guard target != current else { return }

        onMove(current, target)
    }

    /// 들고 있는 행은 이미 옮겨간 칸수만큼 빼야 손가락 아래에 그대로 붙어 있는다.
    private func dragOffset(of item: Item) -> CGFloat {
        guard item.id == draggingID,
              let start = dragStartIndex,
              let current = items.firstIndex(where: { $0.id == item.id }) else { return 0 }
        return dragTranslation - CGFloat(current - start) * rowHeight
    }

    private func endReorder() {
        guard draggingID != nil else { return }
        withAnimation(.snappy(duration: 0.2)) {
            draggingID = nil
            dragStartIndex = nil
            dragTranslation = 0
        }
        onMoveEnded()
    }

    // MARK: - 스와이프 삭제

    /// 스와이프도 같은 이유로 `.global` 이다. 행이 왼쪽으로 밀린 만큼 로컬 좌표가 따라 움직여서
    /// 기본 좌표계로는 이동량이 깎인다.
    private func swipeGesture(_ item: Item) -> some Gesture {
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

    private func closeSwipe() {
        guard swipedID != nil else { return }
        swipeBase = 0
        withAnimation(.snappy(duration: 0.2)) {
            swipeOffset = 0
            swipedID = nil
        }
    }
}

public extension ReorderableList where Footer == EmptyView {
    init(
        _ items: [Item],
        rowHeight: CGFloat,
        onSelect: @escaping (Item) -> Void,
        onDelete: ((Item) -> Void)? = nil,
        onMove: @escaping (Int, Int) -> Void,
        onMoveEnded: @escaping () -> Void,
        @ViewBuilder row: @escaping (Item) -> Row
    ) {
        self.init(
            items,
            rowHeight: rowHeight,
            onSelect: onSelect,
            onDelete: onDelete,
            onMove: onMove,
            onMoveEnded: onMoveEnded,
            row: row,
            footer: { EmptyView() }
        )
    }
}

#Preview {
    struct Sample: Identifiable {
        let id = UUID()
        let name: String
    }

    struct Preview: View {
        @State private var items = [Sample(name: "식비"), Sample(name: "카페"), Sample(name: "교통")]
        @ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = 56

        var body: some View {
            ReorderableList(
                items,
                rowHeight: rowHeight,
                onSelect: { _ in },
                onDelete: { item in items.removeAll { $0.id == item.id } },
                onMove: { source, destination in
                    items.insert(items.remove(at: source), at: destination)
                },
                onMoveEnded: {}
            ) { item in
                Text(item.name)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
            }
            .background(AppColor.background)
        }
    }

    return Preview()
}
