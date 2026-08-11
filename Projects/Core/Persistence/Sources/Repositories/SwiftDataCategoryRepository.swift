import Foundation
import SwiftData
import Domain

@ModelActor
actor SwiftDataCategoryRepository: CategoryRepository {

    func categories() throws -> [ExpenseCategory] {
        try allRecords().map(\.domain)
    }

    func category(id: UUID) throws -> ExpenseCategory? {
        try record(id: id)?.domain
    }

    func insert(_ category: ExpenseCategory, at index: Int) throws {
        var siblings = try allRecords()
        guard siblings.count < ExpenseCategory.maxCount else {
            throw DomainError.categoryLimitReached(max: ExpenseCategory.maxCount)
        }
        let record = CategoryRecord(category)
        modelContext.insert(record)
        siblings.insert(record, at: min(max(index, 0), siblings.count))
        reindex(siblings)
        try save()
    }

    func update(_ category: ExpenseCategory) throws {
        guard let record = try record(id: category.id) else {
            throw DomainError.categoryNotFound(category.id)
        }
        record.apply(category)
        try save()
    }

    func expenseCount(using id: UUID) throws -> Int {
        do {
            return try modelContext.fetchCount(
                FetchDescriptor<ExpenseRecord>(predicate: #Predicate { $0.categoryID == id })
            )
        } catch {
            throw DomainError.storageFailed(String(describing: error))
        }
    }

    /// 기본 카테고리도 지울 수 있고, 그 카테고리를 쓰던 지출도 함께 지운다.
    /// 다만 마지막 하나는 남긴다. 카테고리가 없으면 지출을 추가할 수 없기 때문이다.
    /// 몇 건이 함께 지워지는지는 호출부가 `expenseCount(using:)` 로 먼저 알린다.
    func delete(id: UUID) throws {
        guard let record = try record(id: id) else { throw DomainError.categoryNotFound(id) }
        guard try allRecords().count > 1 else { throw DomainError.lastCategoryNotDeletable }

        let doomed = try expenseRecords(using: id)
        let affectedDays = Set(doomed.map(\.day))
        for expense in doomed {
            modelContext.delete(expense)
        }
        modelContext.delete(record)
        reindex(try allRecords().filter { $0.id != id })
        try save()

        // 지출이 빠진 날짜는 sortOrder 에 구멍이 생기므로 0…n-1 로 다시 매긴다.
        for day in affectedDays {
            reindexExpenses(try expenseRecords(on: day))
        }
        try save()
    }

    func reorder(_ orderedIDs: [UUID]) throws {
        let siblings = try allRecords()
        let byID = Dictionary(siblings.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var ordered = orderedIDs.compactMap { byID[$0] }
        let placed = Set(ordered.map(\.id))
        ordered.append(contentsOf: siblings.filter { !placed.contains($0.id) })
        reindex(ordered)
        try save()
    }

    /// 저장소가 비어 있을 때만 기본 카테고리를 넣는다.
    func seedBuiltInsIfNeeded() throws {
        guard try allRecords().isEmpty else { return }
        for category in BuiltInCategories.all {
            modelContext.insert(CategoryRecord(category))
        }
        try save()
    }

    // MARK: - Private

    private func allRecords() throws -> [CategoryRecord] {
        let descriptor = FetchDescriptor<CategoryRecord>(sortBy: [SortDescriptor(\.sortOrder)])
        do { return try modelContext.fetch(descriptor) }
        catch { throw DomainError.storageFailed(String(describing: error)) }
    }

    private func record(id: UUID) throws -> CategoryRecord? {
        var descriptor = FetchDescriptor<CategoryRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        do { return try modelContext.fetch(descriptor).first }
        catch { throw DomainError.storageFailed(String(describing: error)) }
    }

    private func expenseRecords(using categoryID: UUID) throws -> [ExpenseRecord] {
        let descriptor = FetchDescriptor<ExpenseRecord>(
            predicate: #Predicate { $0.categoryID == categoryID }
        )
        do { return try modelContext.fetch(descriptor) }
        catch { throw DomainError.storageFailed(String(describing: error)) }
    }

    private func expenseRecords(on day: Date) throws -> [ExpenseRecord] {
        let descriptor = FetchDescriptor<ExpenseRecord>(
            predicate: #Predicate { $0.day == day },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        do { return try modelContext.fetch(descriptor) }
        catch { throw DomainError.storageFailed(String(describing: error)) }
    }

    private func reindex(_ records: [CategoryRecord]) {
        for (index, record) in records.enumerated() where record.sortOrder != index {
            record.sortOrder = index
        }
    }

    private func reindexExpenses(_ records: [ExpenseRecord]) {
        for (index, record) in records.enumerated() where record.sortOrder != index {
            record.sortOrder = index
        }
    }

    private func save() throws {
        do { try modelContext.save() }
        catch { throw DomainError.storageFailed(String(describing: error)) }
    }
}
