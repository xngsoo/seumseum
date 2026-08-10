import Foundation
import SwiftData
import Domain

@ModelActor
actor SwiftDataExpenseRepository: ExpenseRepository, DataResetting {

    func expenses(on day: Date) throws -> [Expense] {
        try records(on: day).map(\.domain)
    }

    func expenses(in range: Range<Date>) throws -> [Expense] {
        let lower = range.lowerBound
        let upper = range.upperBound
        let descriptor = FetchDescriptor<ExpenseRecord>(
            predicate: #Predicate { $0.day >= lower && $0.day < upper },
            sortBy: [SortDescriptor(\.day), SortDescriptor(\.sortOrder)]
        )
        return try fetch(descriptor).map(\.domain)
    }

    func insert(_ expense: Expense, at index: Int) throws {
        var siblings = try records(on: expense.date)
        let record = ExpenseRecord(expense)
        modelContext.insert(record)
        siblings.insert(record, at: min(max(index, 0), siblings.count))
        reindex(siblings)
        try save()
    }

    func update(_ expense: Expense) throws {
        guard let record = try record(id: expense.id) else {
            throw DomainError.expenseNotFound(expense.id)
        }
        let previousDay = record.day
        record.apply(expense)

        guard previousDay != expense.date else {
            try save()
            return
        }
        var moved = try records(on: expense.date).filter { $0.id != record.id }
        moved.insert(record, at: 0)
        reindex(moved)
        reindex(try records(on: previousDay))
        try save()
    }

    @discardableResult
    func delete(id: UUID) throws -> Int {
        guard let record = try record(id: id) else { throw DomainError.expenseNotFound(id) }
        let day = record.day
        var siblings = try records(on: day)
        let index = siblings.firstIndex { $0.id == id } ?? 0
        siblings.remove(at: index)
        modelContext.delete(record)
        reindex(siblings)
        try save()
        return index
    }

    func reorder(_ orderedIDs: [UUID], on day: Date) throws {
        let siblings = try records(on: day)
        let byID = Dictionary(siblings.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var ordered = orderedIDs.compactMap { byID[$0] }
        let placed = Set(ordered.map(\.id))
        ordered.append(contentsOf: siblings.filter { !placed.contains($0.id) })
        reindex(ordered)
        try save()
    }

    // MARK: - 초기화

    func deleteAllExpenses() throws {
        do {
            try modelContext.delete(model: ExpenseRecord.self)
        } catch {
            throw DomainError.storageFailed(String(describing: error))
        }
        try save()
    }

    // MARK: - Private

    private func records(on day: Date) throws -> [ExpenseRecord] {
        try fetch(FetchDescriptor<ExpenseRecord>(
            predicate: #Predicate { $0.day == day },
            sortBy: [SortDescriptor(\.sortOrder)]
        ))
    }

    private func record(id: UUID) throws -> ExpenseRecord? {
        var descriptor = FetchDescriptor<ExpenseRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try fetch(descriptor).first
    }

    private func fetch(_ descriptor: FetchDescriptor<ExpenseRecord>) throws -> [ExpenseRecord] {
        do { return try modelContext.fetch(descriptor) }
        catch { throw DomainError.storageFailed(String(describing: error)) }
    }

    private func reindex(_ records: [ExpenseRecord]) {
        for (index, record) in records.enumerated() where record.sortOrder != index {
            record.sortOrder = index
        }
    }

    private func save() throws {
        do { try modelContext.save() }
        catch { throw DomainError.storageFailed(String(describing: error)) }
    }
}
