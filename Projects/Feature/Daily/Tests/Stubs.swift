import Foundation
import Testing
import Shared
import Domain
@testable import Daily

@MainActor
@Suite("DailyViewModel")
struct DailyViewModelTests {

    @Test("합계는 그날 항목 금액의 합이다")
    func total() async {
        let day = CalendarDay.today()
        let categoryID = UUID()
        let repository = StubExpenseRepository(expenses: [
            Expense(amount: 1_200, categoryID: categoryID, date: day, sortOrder: 0),
            Expense(amount: 3_800, categoryID: categoryID, date: day, sortOrder: 1),
        ])
        let viewModel = DailyViewModel(
            expenseRepository: repository,
            categoryRepository: StubCategoryRepository(categories: [])
        )

        await viewModel.load(day: day)
        #expect(viewModel.total == 5_000)
        #expect(!viewModel.isEmpty)
    }

    @Test("항목이 없으면 빈 상태다")
    func empty() async {
        let viewModel = DailyViewModel(
            expenseRepository: StubExpenseRepository(expenses: []),
            categoryRepository: StubCategoryRepository(categories: [])
        )
        await viewModel.load(day: CalendarDay.today())
        #expect(viewModel.isEmpty)
        #expect(viewModel.total == .zero)
    }

    @Test("카테고리는 id로 조회된다")
    func categoryLookup() async {
        let category = ExpenseCategory(name: "식비", symbolName: "fork.knife", colorToken: .orange)
        let day = CalendarDay.today()
        let expense = Expense(amount: 1_000, categoryID: category.id, date: day)
        let viewModel = DailyViewModel(
            expenseRepository: StubExpenseRepository(expenses: [expense]),
            categoryRepository: StubCategoryRepository(categories: [category])
        )

        await viewModel.load(day: day)
        #expect(viewModel.category(for: expense)?.name == "식비")
    }

    @Test("조회에 실패하면 오류 메시지를 남기고 목록을 비운다")
    func failure() async {
        let viewModel = DailyViewModel(
            expenseRepository: StubExpenseRepository(expenses: [], error: .storageFailed("실패")),
            categoryRepository: StubCategoryRepository(categories: [])
        )
        await viewModel.load(day: CalendarDay.today())
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.expenses.isEmpty)
    }
}
