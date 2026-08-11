import Foundation
import Testing
import Shared
import Domain
@testable import Settings

@MainActor
@Suite("CategoryListViewModel")
struct CategoryListViewModelTests {

    private func makeCategories(_ names: [String]) -> [ExpenseCategory] {
        names.enumerated().map { index, name in
            ExpenseCategory(
                name: name, symbolName: "tag.fill", colorToken: .gray,
                sortOrder: index, isBuiltIn: index == 0
            )
        }
    }

    @Test("목록을 순서대로 읽는다")
    func load() async {
        let repository = FakeCategoryRepository(makeCategories(["식비", "교통", "쇼핑"]))
        let viewModel = CategoryListViewModel(categoryRepository: repository)

        await viewModel.load()

        #expect(viewModel.categories.map(\.name) == ["식비", "교통", "쇼핑"])
        #expect(viewModel.capacityText == "12개 중 3개 사용")
        #expect(viewModel.canAdd)
    }

    @Test("최대 개수에 도달하면 추가할 수 없다")
    func full() async {
        let names = (0 ..< ExpenseCategory.maxCount).map { "카테고리\($0)" }
        let viewModel = CategoryListViewModel(
            categoryRepository: FakeCategoryRepository(makeCategories(names))
        )
        await viewModel.load()

        #expect(!viewModel.canAdd)
    }

    @Test("순서를 바꾸면 저장되고 0…n-1 로 다시 매겨진다")
    func move() async {
        let repository = FakeCategoryRepository(makeCategories(["A", "B", "C"]))
        let viewModel = CategoryListViewModel(categoryRepository: repository)
        await viewModel.load()

        await viewModel.move(from: IndexSet(integer: 2), to: 0)

        #expect(viewModel.categories.map(\.name) == ["C", "A", "B"])
        #expect(viewModel.categories.map(\.sortOrder) == [0, 1, 2])
    }

    @Test("드래그 중에는 화면 순서만 바뀌고 저장은 손을 뗄 때 한 번만 한다")
    func moveLocallyDefersSaving() async {
        let repository = FakeCategoryRepository(makeCategories(["A", "B", "C"]))
        let viewModel = CategoryListViewModel(categoryRepository: repository)
        await viewModel.load()

        viewModel.moveLocally(from: 2, to: 1)
        viewModel.moveLocally(from: 1, to: 0)

        #expect(viewModel.categories.map(\.name) == ["C", "A", "B"])
        var stored = try? await repository.categories()
        #expect(stored?.map(\.name) == ["A", "B", "C"])

        await viewModel.commitReorder()

        stored = try? await repository.categories()
        #expect(stored?.map(\.name) == ["C", "A", "B"])
        #expect(stored?.map(\.sortOrder) == [0, 1, 2])
    }

    @Test("드래그 저장이 실패하면 드래그 시작 전 순서로 되돌린다")
    func commitReorderFailureRollsBack() async {
        let repository = FakeCategoryRepository(
            makeCategories(["A", "B", "C"]), failure: .storageFailed("실패")
        )
        let viewModel = CategoryListViewModel(categoryRepository: repository)
        await viewModel.load()

        viewModel.moveLocally(from: 2, to: 1)
        viewModel.moveLocally(from: 1, to: 0)
        await viewModel.commitReorder()

        #expect(viewModel.categories.map(\.name) == ["A", "B", "C"])
        #expect(viewModel.isErrorPresented)
    }

    @Test("순서 변경이 실패하면 이전 순서로 되돌리고 알린다")
    func moveFailure() async {
        let repository = FakeCategoryRepository(
            makeCategories(["A", "B"]), failure: .storageFailed("실패")
        )
        let viewModel = CategoryListViewModel(categoryRepository: repository)
        await viewModel.load()

        await viewModel.move(from: IndexSet(integer: 1), to: 0)

        #expect(viewModel.categories.map(\.name) == ["A", "B"])
        #expect(viewModel.isErrorPresented)
    }

    @Test("삭제하면 목록에서 빠진다")
    func delete() async {
        let repository = FakeCategoryRepository(makeCategories(["식비", "교통"]))
        let viewModel = CategoryListViewModel(categoryRepository: repository)
        await viewModel.load()
        let target = viewModel.categories[1]

        await viewModel.delete(target)

        #expect(viewModel.categories.map(\.name) == ["식비"])
        #expect(!viewModel.isErrorPresented)
    }

    @Test("기본 카테고리를 지우면 사용자에게 이유를 알린다")
    func deleteBuiltIn() async {
        let repository = FakeCategoryRepository(makeCategories(["식비", "교통"]))
        let viewModel = CategoryListViewModel(categoryRepository: repository)
        await viewModel.load()
        let builtIn = viewModel.categories[0]

        await viewModel.delete(builtIn)

        #expect(viewModel.isErrorPresented)
        #expect(viewModel.errorMessage == "기본 카테고리는 삭제할 수 없습니다.")
        #expect(viewModel.categories.count == 2, "목록은 그대로다")
    }
}

/// 0…n-1 불변식과 기본 카테고리 삭제 금지를 흉내내는 메모리 저장소.
private actor FakeCategoryRepository: CategoryRepository {
    private var storage: [ExpenseCategory]
    private let failure: DomainError?

    init(_ categories: [ExpenseCategory], failure: DomainError? = nil) {
        self.storage = Self.reindexed(categories)
        self.failure = failure
    }

    func categories() async throws -> [ExpenseCategory] { storage }

    func category(id: UUID) async throws -> ExpenseCategory? {
        storage.first { $0.id == id }
    }

    func insert(_ category: ExpenseCategory, at index: Int) async throws {
        guard storage.count < ExpenseCategory.maxCount else {
            throw DomainError.categoryLimitReached(max: ExpenseCategory.maxCount)
        }
        storage.insert(category, at: min(max(index, 0), storage.count))
        storage = Self.reindexed(storage)
    }

    func update(_ category: ExpenseCategory) async throws {
        guard let index = storage.firstIndex(where: { $0.id == category.id }) else {
            throw DomainError.categoryNotFound(category.id)
        }
        storage[index] = category
    }

    func delete(id: UUID) async throws {
        guard let index = storage.firstIndex(where: { $0.id == id }) else {
            throw DomainError.categoryNotFound(id)
        }
        guard !storage[index].isBuiltIn else {
            throw DomainError.builtInCategoryNotDeletable(id)
        }
        storage.remove(at: index)
        storage = Self.reindexed(storage)
    }

    func reorder(_ orderedIDs: [UUID]) async throws {
        if let failure { throw failure }
        let byID = Dictionary(storage.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var ordered = orderedIDs.compactMap { byID[$0] }
        let placed = Set(ordered.map(\.id))
        ordered.append(contentsOf: storage.filter { !placed.contains($0.id) })
        storage = Self.reindexed(ordered)
    }

    private static func reindexed(_ items: [ExpenseCategory]) -> [ExpenseCategory] {
        items.enumerated().map { index, item in
            var copy = item
            copy.sortOrder = index
            return copy
        }
    }
}
