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

    func delete(id: UUID) throws {
        guard let record = try record(id: id) else { throw DomainError.categoryNotFound(id) }
        guard !record.isBuiltIn else { throw DomainError.builtInCategoryNotDeletable(id) }
        guard try !isInUse(id) else { throw DomainError.categoryInUse(id) }

        modelContext.delete(record)
        reindex(try allRecords().filter { $0.id != id })
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

    private func isInUse(_ categoryID: UUID) throws -> Bool {
        var descriptor = FetchDescriptor<ExpenseRecord>(
            predicate: #Predicate { $0.categoryID == categoryID }
        )
        descriptor.fetchLimit = 1
        do { return try !modelContext.fetch(descriptor).isEmpty }
        catch { throw DomainError.storageFailed(String(describing: error)) }
    }

    private func reindex(_ records: [CategoryRecord]) {
        for (index, record) in records.enumerated() where record.sortOrder != index {
            record.sortOrder = index
        }
    }

    private func save() throws {
        do { try modelContext.save() }
        catch { throw DomainError.storageFailed(String(describing: error)) }
    }
}
