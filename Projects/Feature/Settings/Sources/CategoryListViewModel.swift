import Foundation
import Observation
import Domain

@MainActor
@Observable
public final class CategoryListViewModel {

    public private(set) var categories: [ExpenseCategory] = []
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
