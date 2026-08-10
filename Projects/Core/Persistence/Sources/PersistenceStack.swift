import Foundation
import Domain

/// App 레이어가 쓰는 유일한 진입점. SwiftData 타입은 밖으로 나가지 않는다.
public struct PersistenceStack: Sendable {
    public let expenses: any ExpenseRepository
    public let categories: any CategoryRepository
    public let settings: any SettingsRepository
    public let reset: any DataResetting

    public init(inMemory: Bool = false, defaults: UserDefaults = .standard) async throws {
        let container = try PersistenceSchema.container(inMemory: inMemory)
        let categoryRepository = SwiftDataCategoryRepository(modelContainer: container)
        try await categoryRepository.seedBuiltInsIfNeeded()

        let expenseRepository = SwiftDataExpenseRepository(modelContainer: container)
        self.expenses = expenseRepository
        self.reset = expenseRepository
        self.categories = categoryRepository
        self.settings = UserDefaultsSettingsRepository(defaults: defaults)
    }
}
