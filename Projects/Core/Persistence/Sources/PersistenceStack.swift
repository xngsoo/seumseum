import Foundation
import Domain

/// App 레이어가 쓰는 유일한 진입점. SwiftData 타입은 밖으로 나가지 않는다.
public struct PersistenceStack: Sendable {
    public let expenses: any ExpenseRepository
    public let categories: any CategoryRepository

    public init(inMemory: Bool = false) async throws {
        let container = try PersistenceSchema.container(inMemory: inMemory)
        let categoryRepository = SwiftDataCategoryRepository(modelContainer: container)
        try await categoryRepository.seedBuiltInsIfNeeded()

        self.expenses = SwiftDataExpenseRepository(modelContainer: container)
        self.categories = categoryRepository
    }
}
