import Foundation
import Observation
import Domain
import Shared

@MainActor
@Observable
public final class ExpenseEditorViewModel {

    public let route: EditorRoute
    public var amountDigits: String = ""
    public var categoryID: UUID?
    public var day: Date
    public var memo: String = ""

    public private(set) var categories: [ExpenseCategory] = []
    public private(set) var isSaving = false
    public private(set) var errorMessage: String?

    private let expenseRepository: any ExpenseRepository
    private let categoryRepository: any CategoryRepository

    public init(
        route: EditorRoute,
        expenseRepository: any ExpenseRepository,
        categoryRepository: any CategoryRepository
    ) {
        self.route = route
        self.expenseRepository = expenseRepository
        self.categoryRepository = categoryRepository

        switch route {
        case let .create(day):
            self.day = day
        case let .edit(expense):
            self.day = expense.date
            self.amountDigits = Self.digits(from: expense.amount)
            self.categoryID = expense.categoryID
            self.memo = expense.memo
        }
    }

    public var isEditing: Bool {
        if case .edit = route { return true }
        return false
    }

    public var title: String { isEditing ? "지출 수정" : "지출 추가" }

    public var amount: Decimal {
        Decimal(string: amountDigits) ?? .zero
    }

    /// 입력 필드에 보이는 금액. 축약하지 않는다.
    public var formattedAmount: String {
        AmountFormatter.full(amount)
    }
    
    public var groupedAmount: String {
        amountDigits.isEmpty ? "" : AmountFormatter.grouped(amount)
    }

    public var canSave: Bool {
        amount > .zero && categoryID != nil && !isSaving
    }

    public func load() async {
        do {
            categories = try await categoryRepository.categories()
            if categoryID == nil { categoryID = categories.first?.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 숫자만 남기고 앞자리 0과 과도한 길이를 정리한다.
    public func updateAmount(_ raw: String) {
        let filtered = raw.filter(\.isNumber)
        let trimmed = String(filtered.drop { $0 == "0" })
        amountDigits = String(trimmed.prefix(12))
    }

    @discardableResult
    public func save() async -> Bool {
        guard canSave, let categoryID else { return false }
        isSaving = true
        defer { isSaving = false }

        do {
            switch route {
            case .create:
                // day 는 이미 달력일이므로 .gmt 로 정규화해야 값이 바뀌지 않는다
                let expense = Expense.make(
                    amount: amount, memo: memo, categoryID: categoryID,
                    pickedDate: day, timeZone: .gmt
                )
                try await expenseRepository.insert(expense, at: 0)
            case let .edit(original):
                var edited = original
                edited.amount = amount
                edited.memo = memo
                edited.categoryID = categoryID
                edited.move(to: day, in: .gmt)
                try await expenseRepository.update(edited)
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private static func digits(from amount: Decimal) -> String {
        var rounded = Decimal()
        var value = amount
        NSDecimalRound(&rounded, &value, 0, .down)
        return NSDecimalNumber(decimal: rounded).stringValue
    }
}
