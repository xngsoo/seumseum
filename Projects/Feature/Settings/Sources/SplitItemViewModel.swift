import Foundation
import Observation
import Domain
import Shared

@MainActor
@Observable
public final class SplitItemViewModel {

    public var isEnabled = false
    public var name = ""
    public var unitAmountDigits = ""
    public var unitLabel = "개"
    public var categoryID: UUID?

    public private(set) var categories: [ExpenseCategory] = []
    public private(set) var errorMessage: String?

    private let categoryRepository: any CategoryRepository

    public init(initial: SplitItem?, categoryRepository: any CategoryRepository) {
        self.categoryRepository = categoryRepository
        if let initial {
            isEnabled = true
            name = initial.name
            unitAmountDigits = Self.digits(from: initial.unitAmount)
            unitLabel = initial.unitLabel
            categoryID = initial.categoryID
        }
    }

    public var unitAmount: Decimal { Decimal(string: unitAmountDigits) ?? .zero }

    public var groupedUnitAmount: String {
        unitAmountDigits.isEmpty ? "" : AmountFormatter.grouped(unitAmount)
    }

    public var canSave: Bool {
        guard isEnabled else { return true }
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && unitAmount > .zero
            && categoryID != nil
    }

    /// 저장할 값. 꺼져 있으면 nil 이고, 그러면 기능이 해제된다.
    public var result: SplitItem? {
        guard isEnabled, let categoryID, unitAmount > .zero else { return nil }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLabel = unitLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        return SplitItem(
            name: trimmedName,
            unitAmount: unitAmount,
            categoryID: categoryID,
            unitLabel: trimmedLabel.isEmpty ? "개" : trimmedLabel
        )
    }

    public func load() async {
        do {
            categories = try await categoryRepository.categories()
            if categoryID == nil || !categories.contains(where: { $0.id == categoryID }) {
                categoryID = categories.first?.id
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func updateUnitAmount(_ raw: String) {
        let filtered = raw.filter(\.isNumber)
        let trimmed = String(filtered.drop { $0 == "0" })
        unitAmountDigits = String(trimmed.prefix(9))
    }

    private static func digits(from amount: Decimal) -> String {
        var rounded = Decimal()
        var value = amount
        NSDecimalRound(&rounded, &value, 0, .down)
        return NSDecimalNumber(decimal: rounded).stringValue
    }
}
