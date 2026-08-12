import SwiftUI

/// 롱프레스 드래그 재정렬과 스와이프 삭제를 직접 다루는 목록.
///
/// `List` 를 쓰지 않는 이유는 재정렬 뒤 마지막 행 아래에 구분선을 되살리고,
/// 행 구성을 다시 적용하는 시점을 우리가 잡을 수 없기 때문이다.
/// 재정렬을 행 높이 단위로 계산하므로 모든 행의 높이는 `rowHeight` 로 같다.
/// 호출부에서 `@ScaledMetric` 으로 넘기면 글자 크기 설정을 따라간다.
///
/// 손짓으로만 쓸 수 있는 재정렬·삭제는 VoiceOver 로 닿지 않으므로
/// 행마다 "위로 이동 / 아래로 이동 / 삭제" 사용자화 동작을 함께 붙인다.
public struct ReorderableList<Item: Identifiable, Row: View, Footer: View>: View {

    // 제스처는 ReorderableList+Gestures.swift 에 있다. 파일이 다르므로 상태는 private 이 아니다.

    let items: [Item]
    let rowHeight: CGFloat
    let onSelect: (Item) -> Void
    /// nil 이면 스와이프 삭제를 붙이지 않는다.
    let onDelete: ((Item) -> Void)?
    /// 드래그하는 동안 화면 순서만 바꾼다.
    let onMove: (Int, Int) -> Void
    /// 손을 뗄 때 한 번만 저장한다.
    let onMoveEnded: () -> Void
    let row: (Item) -> Row
    let footer: () -> Footer

    @State var draggingID: Item.ID?
    /// 드래그를 시작한 자리. 목표 위치를 여기서부터 절대 계산한다.
    @State var dragStartIndex: Int?
    @State var dragTranslation: CGFloat = 0
    /// 자동 스크롤로 흘러간 거리. 손가락이 멈춰 있어도 이만큼 더 끈 것으로 친다.
    @State var autoScrollShift: CGFloat = 0
    @State var autoScrollDirection = 0
    @State var autoScrollTask: Task<Void, Never>?
    /// 자동 스크롤 박자. 값이 바뀔 때마다 뷰가 최신 목록으로 한 칸을 처리한다.
    @State var autoScrollTick = 0
    /// 손가락의 화면 세로 위치. 가장자리에 닿았는지 판단하는 데 쓴다.
    @State var dragScreenY: CGFloat = 0
    @State var swipedID: Item.ID?
    @State var swipeOffset: CGFloat = 0
    @State var swipeBase: CGFloat = 0

    let deleteWidth: CGFloat = 88
    /// 이 폭 안으로 들어오면 목록이 저절로 흐른다.
    let edgeZone: CGFloat = 72

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
        GeometryReader { proxy in
            ScrollViewReader { scroller in
                ScrollView {
                    VStack(spacing: 0) {
                        VStack(spacing: 0) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                rowView(item, at: index)
                            }
                        }
                        // 드래그 중에는 애니메이션을 끈다. 자리 이동이 애니메이션되면
                        // 들고 있는 행이 손가락보다 한 칸씩 뒤처진다.
                        .animation(
                            draggingID == nil ? .snappy(duration: 0.25) : nil,
                            value: items.map(\.id)
                        )

                        footer()
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicators(.hidden)
                .scrollDisabled(draggingID != nil)
                .onChange(of: dragScreenY) { _, _ in
                    updateAutoScroll(in: proxy.frame(in: .global))
                }
                // 박자마다 여기서 처리해야 `items` 가 최신이다. 반복 작업 안에서 하면 낡은 사본을 본다.
                .onChange(of: autoScrollTick) { _, _ in
                    autoScrollStep(scroller)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: draggingID)
        .onChange(of: items.map(\.id)) { _, _ in
            if draggingID == nil { closeSwipe() }
        }
    }

    // MARK: - 행

    private func rowView(_ item: Item, at index: Int) -> some View {
        let isDragging = item.id == draggingID
        let isSwiped = item.id == swipedID

        return ZStack(alignment: .trailing) {
            if let onDelete {
                deleteButton(item, onDelete: onDelete)
                    .opacity(isSwiped ? 1 : 0)
            }

            row(item)
                .padding(.horizontal, AppSpacing.screenMargin)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: rowHeight)
                .background(AppColor.surface)
                .overlay(alignment: .bottom) {
                    if !isDragging, index < items.count - 1 {
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
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onSelect(item) }
        .accessibilityActions {
            if index > 0 {
                Button("위로 이동") { moveByAccessibility(from: index, to: index - 1) }
            }
            if index < items.count - 1 {
                Button("아래로 이동") { moveByAccessibility(from: index, to: index + 1) }
            }
            if let onDelete {
                Button("삭제") { onDelete(item) }
            }
        }
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
        // 스와이프로만 닿는 버튼이라 VoiceOver 에는 사용자화 동작으로 대신 노출한다.
        .accessibilityHidden(true)
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
        @State var items = (1 ... 20).map { Sample(name: "항목 \($0)") }
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
                onMoveEnded: {},
                row: { item in
                    Text(item.name)
                        .font(AppFont.rowTitle)
                        .foregroundStyle(AppColor.textPrimary)
                },
                footer: { EmptyView() }
            )
            .background(AppColor.background)
        }
    }

    return Preview()
}
