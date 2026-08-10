import Foundation
import Domain

/// 0…n-1 불변식을 지키는 메모리 저장소. 실제 구현과 같은 계약을 흉내낸다.
actor FakeExpenseRepository: ExpenseRepository {
    private var storage: [Date: [Expense]] = [:]
    private let failure: DomainError?

    init(_ seed: [Date: [Expense]] = [:], failure: DomainError? = nil) {
        self.failure = failure
        for (day, items) in seed { storage[day] = Self.reindexed(items) }
    }

    func expenses(on day: Date) async throws -> [Expense] {
        if let failure { throw failure }
        return storage[day] ?? []
    }

    func expenses(in range: Range<Date>) async throws -> [Expense] {
        if let failure { throw failure }
        return storage.filter { range.contains($0.key) }.values.flatMap { $0 }
    }

    func insert(_ expense: Expense, at index: Int) async throws {
        var items = storage[expense.date] ?? []
        items.insert(expense, at: min(max(index, 0), items.count))
        storage[expense.date] = Self.reindexed(items)
    }

    func update(_ expense: Expense) async throws {
        guard var items = storage[expense.date],
              let position = items.firstIndex(where: { $0.id == expense.id })
        else { throw DomainError.expenseNotFound(expense.id) }
        items[position] = expense
        storage[expense.date] = Self.reindexed(items)
    }

    @discardableResult
    func delete(id: UUID) async throws -> Int {
        for (day, items) in storage {
            guard let index = items.firstIndex(where: { $0.id == id }) else { continue }
            var remaining = items
            remaining.remove(at: index)
            storage[day] = Self.reindexed(remaining)
            return index
        }
        throw DomainError.expenseNotFound(id)
    }

    func reorder(_ orderedIDs: [UUID], on day: Date) async throws {
        let items = storage[day] ?? []
        let byID = Dictionary(items.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var ordered = orderedIDs.compactMap { byID[$0] }
        let placed = Set(ordered.map(\.id))
        ordered.append(contentsOf: items.filter { !placed.contains($0.id) })
        storage[day] = Self.reindexed(ordered)
    }

    private static func reindexed(_ items: [Expense]) -> [Expense] {
        items.enumerated().map { index, item in
            var copy = item
            copy.sortOrder = index
            return copy
        }
    }
}
