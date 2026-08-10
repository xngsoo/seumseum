import Foundation
import Testing
import Shared
import Domain
@testable import Monthly

@MainActor
@Suite("MonthlyViewModel")
struct MonthlyViewModelTests {

    private func day(_ y: Int, _ m: Int, _ d: Int) throws -> Date {
        try #require(CalendarDay.date(year: y, month: m, day: d))
    }

    @Test("일별 합계를 날짜별로 모은다")
    func totalsByDay() async throws {
        let first = try day(2026, 8, 1)
        let second = try day(2026, 8, 2)
        let category = UUID()
        let repository = FixedExpenseRepository(expenses: [
            Expense(amount: 1_000, categoryID: category, date: first),
            Expense(amount: 2_500, categoryID: category, date: first),
            Expense(amount: 4_000, categoryID: category, date: second),
        ])
        let viewModel = MonthlyViewModel(expenseRepository: repository)

        await viewModel.load(month: first)

        #expect(viewModel.total(on: first) == 3_500)
        #expect(viewModel.total(on: second) == 4_000)
        #expect(viewModel.monthTotal == 7_500)
    }

    @Test("기록이 없는 날은 nil 이다")
    func missingDay() async throws {
        let first = try day(2026, 8, 1)
        let viewModel = MonthlyViewModel(expenseRepository: FixedExpenseRepository(expenses: []))
        await viewModel.load(month: first)
        #expect(viewModel.total(on: first) == nil)
        #expect(viewModel.monthTotal == .zero)
    }

    @Test("조회 범위는 그 달의 반개구간이다")
    func requestedRange() async throws {
        let mid = try day(2026, 8, 15)
        let repository = FixedExpenseRepository(expenses: [])
        let viewModel = MonthlyViewModel(expenseRepository: repository)

        await viewModel.load(month: mid)

        let requested = await repository.lastRange
        #expect(requested?.lowerBound == (try day(2026, 8, 1)))
        #expect(requested?.upperBound == (try day(2026, 9, 1)))
    }

    @Test("조회에 실패하면 합계를 비운다")
    func failure() async throws {
        let viewModel = MonthlyViewModel(
            expenseRepository: FixedExpenseRepository(expenses: [], failure: .storageFailed("실패"))
        )
        await viewModel.load(month: try day(2026, 8, 1))
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.monthTotal == .zero)
    }
}

private actor FixedExpenseRepository: ExpenseRepository {
    private let expenses: [Expense]
    private let failure: DomainError?
    private(set) var lastRange: Range<Date>?

    init(expenses: [Expense], failure: DomainError? = nil) {
        self.expenses = expenses
        self.failure = failure
    }

    func expenses(on day: Date) async throws -> [Expense] { [] }

    func expenses(in range: Range<Date>) async throws -> [Expense] {
        lastRange = range
        if let failure { throw failure }
        return expenses.filter { range.contains($0.date) }
    }

    func insert(_ expense: Expense, at index: Int) async throws {}
    func update(_ expense: Expense) async throws {}
    func delete(id: UUID) async throws -> Int { 0 }
    func reorder(_ orderedIDs: [UUID], on day: Date) async throws {}
}
