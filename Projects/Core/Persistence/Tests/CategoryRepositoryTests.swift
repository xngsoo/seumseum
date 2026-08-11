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

    @Test("기본 카테고리도 삭제된다")
    func builtInDeletable() async throws {
        let repository = try await makeStack().categories
        let first = try #require(try await repository.categories().first)

        try await repository.delete(id: first.id)

        let remaining = try await repository.categories()
        #expect(remaining.count == BuiltInCategories.all.count - 1)
        #expect(!remaining.contains { $0.id == first.id })
        #expect(remaining.map(\.sortOrder) == Array(0 ..< remaining.count))
    }

    @Test("마지막 하나는 삭제할 수 없다")
    func lastNotDeletable() async throws {
        let repository = try await makeStack().categories
        let all = try await repository.categories()
        for category in all.dropLast() {
            try await repository.delete(id: category.id)
        }
        let last = try #require(try await repository.categories().first)

        await #expect(throws: DomainError.lastCategoryNotDeletable) {
            try await repository.delete(id: last.id)
        }
        #expect(try await repository.categories().count == 1)
    }

    @Test("사용 중인 카테고리를 지우면 그 지출도 함께 지워지고 남은 날짜는 0…n-1")
    func deleteCascadesToExpenses() async throws {
        let stack = try await makeStack()
        let day = CalendarDay.today()
        let custom = ExpenseCategory(name: "여행", symbolName: "airplane", colorToken: .blue)
        let keeper = try #require(try await stack.categories.categories().first)
        try await stack.categories.insert(custom, at: 0)

        // 같은 날짜에 두 카테고리를 섞어 넣는다. 지운 뒤 순서가 다시 매겨지는지 보려는 것이다.
        try await stack.expenses.insert(
            Expense(amount: 1_000, memo: "남는다", categoryID: keeper.id, date: day), at: 0
        )
        try await stack.expenses.insert(
            Expense(amount: 2_000, memo: "지워진다", categoryID: custom.id, date: day), at: 0
        )
        #expect(try await stack.categories.expenseCount(using: custom.id) == 1)

        try await stack.categories.delete(id: custom.id)

        let remaining = try await stack.expenses.expenses(on: day)
        #expect(remaining.map(\.memo) == ["남는다"])
        #expect(remaining.map(\.sortOrder) == [0])
        #expect(try await stack.categories.category(id: custom.id) == nil)
    }

    @Test("사용하지 않는 사용자 카테고리는 삭제되고 순서가 다시 매겨진다")
    func deleteCustom() async throws {
        let repository = try await makeStack().categories
        let custom = ExpenseCategory(name: "여행", symbolName: "airplane", colorToken: .blue)
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

@Suite("카테고리 개수 제한")
struct CategoryLimitTests {

    @Test("최대 개수를 넘겨 추가하면 categoryLimitReached")
    func limit() async throws {
        let repository = try await PersistenceStack(inMemory: true).categories
        let seeded = try await repository.categories().count

        for index in seeded ..< ExpenseCategory.maxCount {
            try await repository.insert(
                ExpenseCategory(name: "추가\(index)", symbolName: "star", colorToken: .gray),
                at: index
            )
        }
        #expect(try await repository.categories().count == ExpenseCategory.maxCount)

        await #expect(throws: DomainError.categoryLimitReached(max: ExpenseCategory.maxCount)) {
            try await repository.insert(
                ExpenseCategory(name: "초과", symbolName: "star", colorToken: .gray), at: 0
            )
        }
    }
}
