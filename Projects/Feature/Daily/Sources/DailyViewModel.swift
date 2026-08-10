import Foundation
import Observation
import Domain
import Shared

@MainActor
@Observable
public final class DailyViewModel {

    public struct PendingUndo: Equatable, Sendable {
        public let expense: Expense
        public let index: Int
    }

    public private(set) var expenses: [Expense] = []
    public private(set) var categories: [UUID: ExpenseCategory] = [:]
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?
    public private(set) var pendingUndo: PendingUndo?

    /// 마지막으로 조회한 날짜. 소유자는 AppNavigation이고 여기서는 캐시로만 쓴다.
    private var day: Date = CalendarDay.today()
    private var undoTimeout: Task<Void, Never>?

    private let expenseRepository: any ExpenseRepository
    private let categoryRepository: any CategoryRepository

    public init(
        expenseRepository: any ExpenseRepository,
        categoryRepository: any CategoryRepository
    ) {
        self.expenseRepository = expenseRepository
        self.categoryRepository = categoryRepository
    }

    public var total: Decimal {
        expenses.reduce(Decimal.zero) { $0 + $1.amount }
    }

    public var isEmpty: Bool { expenses.isEmpty }

    public func category(for expense: Expense) -> ExpenseCategory? {
        categories[expense.categoryID]
    }

    // MARK: - 조회

    public func load(day: Date) async {
        self.day = day
        isLoading = true
        errorMessage = nil
        do {
            async let loadedExpenses = expenseRepository.expenses(on: day)
            async let loadedCategories = categoryRepository.categories()
            let (fetched, allCategories) = try await (loadedExpenses, loadedCategories)
            expenses = fetched
            categories = Dictionary(
                allCategories.map { ($0.id, $0) },
                uniquingKeysWith: { first, _ in first }
            )
        } catch {
            errorMessage = error.localizedDescription
            expenses = []
        }
        isLoading = false
    }

    // MARK: - 재정렬

    public func move(from offsets: IndexSet, to destination: Int) async {
        let previous = expenses
        var reordered = expenses
        reordered.move(fromOffsets: offsets, toOffset: destination)
        expenses = reordered

        do {
            try await expenseRepository.reorder(reordered.map(\.id), on: day)
        } catch {
            expenses = previous
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - 삭제와 취소

    public func delete(_ expense: Expense) async {
        do {
            let index = try await expenseRepository.delete(id: expense.id)
            expenses.removeAll { $0.id == expense.id }
            startUndoWindow(PendingUndo(expense: expense, index: index))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func undoDelete() async {
        guard let pending = pendingUndo else { return }
        dismissUndo()
        do {
            try await expenseRepository.insert(pending.expense, at: pending.index)
            await load(day: day)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func dismissUndo() {
        undoTimeout?.cancel()
        undoTimeout = nil
        pendingUndo = nil
    }

    private func startUndoWindow(_ pending: PendingUndo) {
        undoTimeout?.cancel()
        pendingUndo = pending
        undoTimeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            self?.pendingUndo = nil
        }
    }
}
