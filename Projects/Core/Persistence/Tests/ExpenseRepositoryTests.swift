import Foundation
import Testing
import Shared
import Domain
@testable import Persistence

@Suite("ExpenseRepository")
struct ExpenseRepositoryTests {

    private func makeStack() async throws -> PersistenceStack {
        try await PersistenceStack(inMemory: true)
    }

    private func add(
        _ repository: any ExpenseRepository, _ memo: String, on day: Date, at index: Int = 0
    ) async throws -> Expense {
        let expense = Expense(amount: 1_000, memo: memo, categoryID: UUID(), date: day)
        try await repository.insert(expense, at: index)
        return expense
    }

    private func memos(_ repository: any ExpenseRepository, on day: Date) async throws -> [String] {
        try await repository.expenses(on: day).map(\.memo)
    }

    private func orders(_ repository: any ExpenseRepository, on day: Date) async throws -> [Int] {
        try await repository.expenses(on: day).map(\.sortOrder)
    }

    @Test("새 항목은 0번에 들어가 맨 위에 온다")
    func insertsAtTop() async throws {
        let repository = try await makeStack().expenses
        let day = CalendarDay.today()
        for memo in ["첫째", "둘째", "셋째"] { _ = try await add(repository, memo, on: day) }

        #expect(try await memos(repository, on: day) == ["셋째", "둘째", "첫째"])
        #expect(try await orders(repository, on: day) == [0, 1, 2])
    }

    @Test("범위를 넘는 인덱스는 끝으로 잘린다")
    func clampsIndex() async throws {
        let repository = try await makeStack().expenses
        let day = CalendarDay.today()
        _ = try await add(repository, "첫째", on: day)
        _ = try await add(repository, "끝", on: day, at: 99)

        #expect(try await memos(repository, on: day) == ["첫째", "끝"])
        #expect(try await orders(repository, on: day) == [0, 1])
    }

    @Test("삭제는 지워진 인덱스를 반환하고 0…n-1을 유지한다")
    func deleteReturnsIndex() async throws {
        let repository = try await makeStack().expenses
        let day = CalendarDay.today()
        _ = try await add(repository, "C", on: day)
        let middle = try await add(repository, "B", on: day)
        _ = try await add(repository, "A", on: day)
        // 화면 순서: A, B, C

        let removedIndex = try await repository.delete(id: middle.id)
        #expect(removedIndex == 1)
        #expect(try await memos(repository, on: day) == ["A", "C"])
        #expect(try await orders(repository, on: day) == [0, 1])
    }

    @Test("삭제 취소는 원래 자리로 되돌린다")
    func undoRestoresPosition() async throws {
        let repository = try await makeStack().expenses
        let day = CalendarDay.today()
        _ = try await add(repository, "C", on: day)
        let middle = try await add(repository, "B", on: day)
        _ = try await add(repository, "A", on: day)

        let index = try await repository.delete(id: middle.id)
        try await repository.insert(middle, at: index)

        #expect(try await memos(repository, on: day) == ["A", "B", "C"])
        #expect(try await orders(repository, on: day) == [0, 1, 2])
    }

    @Test("재정렬은 넘긴 순서대로 0…n-1을 다시 매긴다")
    func reorder() async throws {
        let repository = try await makeStack().expenses
        let day = CalendarDay.today()
        let c = try await add(repository, "C", on: day)
        let b = try await add(repository, "B", on: day)
        let a = try await add(repository, "A", on: day)

        try await repository.reorder([c.id, a.id, b.id], on: day)
        #expect(try await memos(repository, on: day) == ["C", "A", "B"])
        #expect(try await orders(repository, on: day) == [0, 1, 2])
    }

    @Test("날짜를 바꾸면 양쪽 날짜가 모두 0…n-1을 유지한다")
    func updateAcrossDays() async throws {
        let repository = try await makeStack().expenses
        let monday = CalendarDay.today()
        let tuesday = CalendarDay.adding(days: 1, to: monday)

        _ = try await add(repository, "월-2", on: monday)
        var moving = try await add(repository, "월-1", on: monday)
        _ = try await add(repository, "화-1", on: tuesday)

        moving.move(to: tuesday)
        try await repository.update(moving)

        #expect(try await memos(repository, on: monday) == ["월-2"])
        #expect(try await orders(repository, on: monday) == [0])
        #expect(try await memos(repository, on: tuesday) == ["월-1", "화-1"])
        #expect(try await orders(repository, on: tuesday) == [0, 1])
    }

    @Test("기간 조회는 날짜·순서로 정렬해 반환한다")
    func fetchRange() async throws {
        let repository = try await makeStack().expenses
        let day1 = CalendarDay.today()
        let day2 = CalendarDay.adding(days: 1, to: day1)
        let day3 = CalendarDay.adding(days: 2, to: day1)

        _ = try await add(repository, "1일차", on: day1)
        _ = try await add(repository, "2일차-b", on: day2)
        _ = try await add(repository, "2일차-a", on: day2)
        _ = try await add(repository, "범위밖", on: day3)

        let result = try await repository.expenses(in: day1 ..< day3)
        #expect(result.map(\.memo) == ["1일차", "2일차-a", "2일차-b"])
    }

    @Test("없는 항목을 지우면 expenseNotFound")
    func deleteMissing() async throws {
        let repository = try await makeStack().expenses
        let id = UUID()
        await #expect(throws: DomainError.expenseNotFound(id)) {
            _ = try await repository.delete(id: id)
        }
    }
}
