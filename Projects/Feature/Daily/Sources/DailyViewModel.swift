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

    /// 화면에 실제로 그려지고 있는 날짜. 조회가 끝나야 바뀐다.
    /// 날짜 전환 애니메이션은 이 값을 기준으로 삼아야 이전 날짜 위에 새 목록이
    /// 잠깐 겹쳐 보이는 일이 없다.
    public private(set) var loadedDay: Date = CalendarDay.today()

    /// 마지막으로 조회를 요청한 날짜. 소유자는 AppNavigation이고 여기서는 캐시로만 쓴다.
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
            loadedDay = day
        } catch {
            errorMessage = error.localizedDescription
            expenses = []
            loadedDay = day
        }
        isLoading = false
    }

    // MARK: - 삭제 취소

    /// 수정 화면이 지운 기록을 넘겨받아 취소할 수 있는 시간을 연다.
    /// 삭제 자체는 수정 화면이 이미 마쳤다.
    public func registerUndo(expense: Expense, at index: Int) {
        startUndoWindow(PendingUndo(expense: expense, index: index))
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
