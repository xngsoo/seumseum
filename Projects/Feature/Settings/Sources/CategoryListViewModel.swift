import Foundation
import Observation
import Domain

@MainActor
@Observable
public final class CategoryListViewModel {

    /// 지출이 딸린 카테고리를 지우려 할 때, 사용자에게 확인받는 동안 들고 있는 값.
    public struct PendingDeletion: Equatable, Sendable {
        public let category: ExpenseCategory
        public let expenseCount: Int
    }

    public private(set) var categories: [ExpenseCategory] = []
    public private(set) var pendingDeletion: PendingDeletion?
    public private(set) var errorMessage: String?
    public var isErrorPresented = false

    private let categoryRepository: any CategoryRepository
    /// 드래그를 시작하기 전의 순서. 저장에 실패하면 이 순서로 되돌린다.
    private var orderBeforeReorder: [ExpenseCategory]?

    public init(categoryRepository: any CategoryRepository) {
        self.categoryRepository = categoryRepository
    }

    public var canAdd: Bool { categories.count < ExpenseCategory.maxCount }

    /// 남은 자리 안내. `12개 중 8개 사용`
    public var capacityText: String {
        "\(ExpenseCategory.maxCount)개 중 \(categories.count)개 사용"
    }

    /// 화면 위쪽에 짧게 적는 자리 안내. `8 / 12`
    public var countText: String {
        "\(categories.count) / \(ExpenseCategory.maxCount)"
    }

    public func canMoveUp(_ category: ExpenseCategory) -> Bool {
        index(of: category).map { $0 > 0 } ?? false
    }

    public func canMoveDown(_ category: ExpenseCategory) -> Bool {
        index(of: category).map { $0 < categories.count - 1 } ?? false
    }

    /// 한 칸 위나 아래로 옮기고 곧바로 저장한다.
    public func move(_ category: ExpenseCategory, by offset: Int) async {
        guard let source = index(of: category) else { return }
        let destination = source + offset
        guard categories.indices.contains(destination) else { return }
        moveLocally(from: source, to: destination)
        await commitReorder()
    }

    private func index(of category: ExpenseCategory) -> Int? {
        categories.firstIndex { $0.id == category.id }
    }

    public func load() async {
        do {
            categories = try await categoryRepository.categories()
        } catch {
            present(error)
        }
    }

    public func move(from offsets: IndexSet, to destination: Int) async {
        var reordered = categories
        reordered.move(fromOffsets: offsets, toOffset: destination)
        orderBeforeReorder = orderBeforeReorder ?? categories
        categories = reordered
        await commitReorder()
    }

    /// 드래그하는 동안 화면 순서만 바꾼다. 저장은 `commitReorder()` 가 한 번만 한다.
    public func moveLocally(from source: Int, to destination: Int) {
        guard source != destination,
              categories.indices.contains(source),
              categories.indices.contains(destination) else { return }

        orderBeforeReorder = orderBeforeReorder ?? categories
        var reordered = categories
        reordered.insert(reordered.remove(at: source), at: destination)
        categories = reordered
    }

    /// 드래그를 끝낼 때 바뀐 순서를 저장한다. 실패하면 시작 전 순서로 되돌린다.
    public func commitReorder() async {
        guard let previous = orderBeforeReorder else { return }
        orderBeforeReorder = nil
        guard previous.map(\.id) != categories.map(\.id) else { return }

        do {
            try await categoryRepository.reorder(categories.map(\.id))
            await load()
        } catch {
            categories = previous
            present(error)
        }
    }

    // MARK: - 삭제

    /// 쓰고 있는 지출이 없으면 바로 지우고, 있으면 확인부터 받는다.
    public func requestDelete(_ category: ExpenseCategory) async {
        do {
            let count = try await categoryRepository.expenseCount(using: category.id)
            guard count > 0 else {
                await delete(category)
                return
            }
            pendingDeletion = PendingDeletion(category: category, expenseCount: count)
        } catch {
            present(error)
        }
    }

    /// 확인 창의 대상을 꺼내면서 비운다.
    /// 창이 닫히며 `cancelDeletion()` 이 뒤따라 불려도, 이미 꺼낸 값으로 삭제를 이어갈 수 있다.
    public func takePendingDeletion() -> ExpenseCategory? {
        defer { pendingDeletion = nil }
        return pendingDeletion?.category
    }

    public func confirmDeletion() async {
        guard let category = takePendingDeletion() else { return }
        await delete(category)
    }

    public func cancelDeletion() {
        pendingDeletion = nil
    }

    /// 확인 창에 쓸 문구. 함께 지워지는 지출 건수를 밝힌다.
    public var deletionTitle: String {
        guard let pending = pendingDeletion else { return "" }
        return "‘\(pending.category.name)’을 삭제할까요?"
    }

    public var deletionMessage: String {
        guard let pending = pendingDeletion else { return "" }
        return """
        이 카테고리로 기록한 지출 \(pending.expenseCount)건도 함께 지워집니다.
        되돌릴 수 없습니다.
        """
    }

    public func delete(_ category: ExpenseCategory) async {
        do {
            try await categoryRepository.delete(id: category.id)
            await load()
        } catch {
            present(error)
        }
    }

    /// 저장소가 던진 도메인 에러를 그대로 보여준다. LocalizedError 라 사용자 문구가 이미 들어 있다.
    private func present(_ error: Error) {
        errorMessage = error.localizedDescription
        isErrorPresented = true
    }
}
