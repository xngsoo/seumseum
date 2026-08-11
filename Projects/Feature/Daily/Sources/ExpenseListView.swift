import SwiftUI
import DesignSystem
import Domain
import Shared

/// 탭 1의 지출 목록. `List` 를 쓰지 않고 직접 그린다.
///
/// `List` 는 재정렬 뒤 마지막 행 아래에 구분선을 되살리고, 행 구성을 다시 적용하는 시점을
/// 우리가 잡을 수 없다. 그래서 구분선·재정렬·스와이프 삭제를 모두 여기서 다룬다.
struct ExpenseListView: View {

    let expenses: [Expense]
    let categories: [UUID: ExpenseCategory]
    let onSelect: (Expense) -> Void
    let onDelete: (Expense) -> Void
    /// 드래그하는 동안 화면 순서만 바꾼다.
    let onMove: (Int, Int) -> Void
    /// 손을 뗄 때 한 번만 저장한다.
    let onMoveEnded: () -> Void

    /// 재정렬은 행 높이를 단위로 계산하므로 높이가 정해져 있어야 한다.
    @ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = 68

    @State private var draggingID: UUID?
    /// 드래그를 시작한 자리. 목표 위치를 여기서부터 절대 계산한다.
    @State private var dragStartIndex: Int?
    @State private var dragTranslation: CGFloat = 0
    @State private var swipedID: UUID?
    @State private var swipeOffset: CGFloat = 0
    @State private var swipeBase: CGFloat = 0

    private let deleteWidth: CGFloat = 88

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(expenses) { expense in
                    row(expense)
                }
            }
            // 드래그 중에는 애니메이션을 끈다. 자리 이동이 애니메이션되면
            // 들고 있는 행이 손가락보다 한 칸씩 뒤처진다.
            .animation(draggingID == nil ? .snappy(duration: 0.25) : nil, value: expenses.map(\.id))
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDisabled(draggingID != nil)
        .sensoryFeedback(.selection, trigger: draggingID)
        .onChange(of: expenses.map(\.id)) { _, _ in
            if draggingID == nil { closeSwipe() }
        }
    }

    // MARK: - 행

    private func row(_ expense: Expense) -> some View {
        let isDragging = expense.id == draggingID
        let isSwiped = expense.id == swipedID

        return ZStack(alignment: .trailing) {
            deleteButton(expense)
                .opacity(isSwiped ? 1 : 0)
                .accessibilityHidden(!isSwiped)

            ExpenseRow(
                expense: expense,
                category: categories[expense.categoryID],
                height: rowHeight,
                showsSeparator: !isDragging && expense.id != expenses.last?.id
            )
            .offset(x: isSwiped ? swipeOffset : 0)
        }
        .frame(height: rowHeight)
        .scaleEffect(isDragging ? 1.02 : 1)
        .shadow(color: .black.opacity(isDragging ? 0.18 : 0), radius: 8, y: 4)
        .offset(y: dragOffset(of: expense))
        .zIndex(isDragging ? 1 : 0)
        .contentShape(Rectangle())
        .onTapGesture { tap(expense) }
        // 둘 다 simultaneous 여야 한다. `gesture` 로 붙이면 스크롤뷰의 팬보다 우선권을 가져서,
        // 행이 화면을 채웠을 때 손가락이 늘 행 위에서 시작하므로 스크롤이 아예 시작되지 않는다.
        .simultaneousGesture(reorderGesture(expense))
        .simultaneousGesture(swipeGesture(expense))
        .transition(.opacity)
    }

    private func deleteButton(_ expense: Expense) -> some View {
        Button {
            closeSwipe()
            onDelete(expense)
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

    private func tap(_ expense: Expense) {
        if swipedID == nil {
            onSelect(expense)
        } else {
            closeSwipe()
        }
    }

    // MARK: - 롱프레스 드래그 재정렬

    /// 좌표계가 `.global` 인 것이 중요하다. 기본값인 `.local` 은 행 자신의 좌표계라서
    /// 자리가 바뀌거나 `offset` 이 걸리면 손가락이 멈춰 있어도 `translation` 이 튄다.
    /// 그 값으로 다시 목표 자리를 정하면 되먹임이 생겨 행이 두 자리를 오간다.
    private func reorderGesture(_ expense: Expense) -> some Gesture {
        LongPressGesture(minimumDuration: 0.35)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .global))
            .onChanged { value in
                guard case let .second(_, drag) = value else { return }
                if draggingID != expense.id {
                    closeSwipe()
                    draggingID = expense.id
                    dragStartIndex = expenses.firstIndex { $0.id == expense.id }
                    dragTranslation = 0
                }
                guard let drag else { return }
                dragTranslation = drag.translation.height
                reorderIfNeeded(expense)
            }
            .onEnded { _ in endReorder() }
    }

    /// 목표 자리는 항상 "시작 자리 + 총 이동량 ÷ 행 높이" 로 구한다.
    /// 한 칸 옮길 때마다 이동량을 깎는 방식은 다음 이벤트가 원래 이동량으로 덮어써서
    /// 같은 손짓에 여러 칸이 계속 밀린다.
    private func reorderIfNeeded(_ expense: Expense) {
        guard let start = dragStartIndex,
              let current = expenses.firstIndex(where: { $0.id == expense.id }) else { return }

        let shift = Int((dragTranslation / rowHeight).rounded())
        let target = min(max(start + shift, 0), expenses.count - 1)
        guard target != current else { return }

        onMove(current, target)
    }

    /// 들고 있는 행은 이미 옮겨간 칸수만큼 빼야 손가락 아래에 그대로 붙어 있는다.
    private func dragOffset(of expense: Expense) -> CGFloat {
        guard expense.id == draggingID,
              let start = dragStartIndex,
              let current = expenses.firstIndex(where: { $0.id == expense.id }) else { return 0 }
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
    private func swipeGesture(_ expense: Expense) -> some Gesture {
        DragGesture(minimumDistance: 12, coordinateSpace: .global)
            .onChanged { value in
                guard draggingID == nil else { return }
                // 세로로 끄는 손짓은 스크롤에 넘긴다.
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                if swipedID != expense.id {
                    swipedID = expense.id
                    swipeBase = 0
                }
                swipeOffset = min(max(swipeBase + value.translation.width, -deleteWidth * 1.2), 0)
            }
            .onEnded { _ in
                guard swipedID == expense.id else { return }
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

#Preview {
    let food = ExpenseCategory(name: "식비", symbolName: "fork.knife", colorToken: .orange)
    let cafe = ExpenseCategory(name: "카페", symbolName: "cup.and.saucer", colorToken: .brown)
    let day = CalendarDay.today()

    return ExpenseListView(
        expenses: [
            Expense(amount: 12_800, memo: "점심 김치찌개", categoryID: food.id, date: day, sortOrder: 0),
            Expense(amount: 4_500, memo: "아메리카노", categoryID: cafe.id, date: day, sortOrder: 1),
        ],
        categories: [food.id: food, cafe.id: cafe],
        onSelect: { _ in },
        onDelete: { _ in },
        onMove: { _, _ in },
        onMoveEnded: {}
    )
    .background(AppColor.background)
}
