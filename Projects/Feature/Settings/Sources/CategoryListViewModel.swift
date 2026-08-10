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
        let previous = categories
        var reordered = categories
        reordered.move(fromOffsets: offsets, toOffset: destination)
        categories = reordered

        do {
            try await categoryRepository.reorder(reordered.map(\.id))
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
