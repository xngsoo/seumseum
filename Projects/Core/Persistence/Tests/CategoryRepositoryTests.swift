import Foundation
import Testing
import Shared
import Domain
@testable import Persistence

@Suite("CategoryRepository")
struct CategoryRepositoryTests {

    private func makeStack() async throws -> PersistenceStack {
        try await PersistenceStack(inMemory: true)
    }

    @Test("첫 실행에 기본 카테고리가 채워진다")
    func seeding() async throws {
        let repository = try await makeStack().categories
        let categories = try await repository.categories()
        #expect(categories.count == BuiltInCategories.all.count)
        #expect(categories.map(\.sortOrder) == Array(0 ..< categories.count))
    }

    @Test("기본 카테고리는 삭제할 수 없다")
    func builtInNotDeletable() async throws {
        let repository = try await makeStack().categories
        let first = try #require(try await repository.categories().first)
        await #expect(throws: DomainError.builtInCategoryNotDeletable(first.id)) {
            try await repository.delete(id: first.id)
        }
    }

    @Test("사용 중인 카테고리는 삭제할 수 없다")
    func inUseNotDeletable() async throws {
        let stack = try await makeStack()
        let custom = ExpenseCategory(name: "여행", symbolName: "airplane", colorToken: "blue")
        try await stack.categories.insert(custom, at: 0)

        try await stack.expenses.insert(
            Expense(amount: 1_000, categoryID: custom.id, date: CalendarDay.today()), at: 0
        )

        await #expect(throws: DomainError.categoryInUse(custom.id)) {
            try await stack.categories.delete(id: custom.id)
        }
    }

    @Test("사용하지 않는 사용자 카테고리는 삭제되고 순서가 다시 매겨진다")
    func deleteCustom() async throws {
        let repository = try await makeStack().categories
        let custom = ExpenseCategory(name: "여행", symbolName: "airplane", colorToken: "blue")
        try await repository.insert(custom, at: 0)
        #expect(try await repository.categories().first?.name == "여행")

        try await repository.delete(id: custom.id)
        let remaining = try await repository.categories()
        #expect(remaining.count == BuiltInCategories.all.count)
        #expect(remaining.map(\.sortOrder) == Array(0 ..< remaining.count))
    }

    @Test("수정은 isBuiltIn을 바꾸지 못한다")
    func updateCannotFlipBuiltIn() async throws {
        let repository = try await makeStack().categories
        var first = try #require(try await repository.categories().first)
        let id = first.id
        first.name = "이름변경"
        try await repository.update(first)

        let reloaded = try #require(try await repository.category(id: id))
        #expect(reloaded.name == "이름변경")
        #expect(reloaded.isBuiltIn)
    }

    @Test("재정렬은 0…n-1을 다시 매긴다")
    func reorder() async throws {
        let repository = try await makeStack().categories
        let original = try await repository.categories()
        let reversed = original.map(\.id).reversed().map { $0 }

        try await repository.reorder(reversed)
        let result = try await repository.categories()
        #expect(result.map(\.id) == reversed)
        #expect(result.map(\.sortOrder) == Array(0 ..< result.count))
    }
}
