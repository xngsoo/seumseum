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

    /// 분리할 수량. 0 이면 분리하지 않는다.
    public var splitQuantity = 0

    public private(set) var categories: [ExpenseCategory] = []
    public private(set) var splitItem: SplitItem?
    public private(set) var isSaving = false
    public private(set) var errorMessage: String?

    private let expenseRepository: any ExpenseRepository
    private let categoryRepository: any CategoryRepository
    private let settingsRepository: any SettingsRepository

    public init(
        route: EditorRoute,
        expenseRepository: any ExpenseRepository,
        categoryRepository: any CategoryRepository,
        settingsRepository: any SettingsRepository
    ) {
        self.route = route
        self.expenseRepository = expenseRepository
        self.categoryRepository = categoryRepository
        self.settingsRepository = settingsRepository

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

    // MARK: - 정액 품목 분리

    /// 분리 입력을 보여줄지. 수정 화면에서는 감춘다.
    /// 이미 나뉜 기록을 다시 나누면 어느 쪽을 고쳐야 할지 모호해진다.
    public var showsSplitField: Bool {
        splitItem != nil && !isEditing
    }

    /// 떼어낼 금액
    public var splitAmount: Decimal {
        splitItem?.amount(for: splitQuantity) ?? .zero
    }

    /// 원래 카테고리에 남는 금액
    public var remainingAmount: Decimal {
        max(amount - splitAmount, .zero)
    }

    public var isSplitting: Bool { splitQuantity > 0 && splitItem != nil }

    /// 분리 금액이 총액을 넘으면 저장할 수 없다.
    public var isSplitAmountValid: Bool {
        guard let splitItem, splitQuantity > 0 else { return true }
        return splitItem.canSplit(quantity: splitQuantity, from: amount)
    }

    /// 분리 결과 미리보기. `담배 2갑 9,000원 · 편의점 3,500원`
    public var splitPreview: String? {
        guard let splitItem, isSplitting else { return nil }
        guard isSplitAmountValid else { return "금액이 부족합니다" }
        let categoryName = categories.first { $0.id == categoryID }?.name ?? "나머지"
        let head = "\(splitItem.memo(for: splitQuantity)) \(AmountFormatter.full(splitAmount))"
        guard remainingAmount > .zero else { return head }
        return "\(head) · \(categoryName) \(AmountFormatter.full(remainingAmount))"
    }

    public var canSave: Bool {
        amount > .zero && categoryID != nil && !isSaving && isSplitAmountValid
    }

    public func load() async {
        do {
            async let loadedCategories = categoryRepository.categories()
            async let loadedSettings = settingsRepository.settings()
            let (allCategories, settings) = try await (loadedCategories, loadedSettings)
            categories = allCategories
            if categoryID == nil { categoryID = allCategories.first?.id }
            // 대상 카테고리가 지워졌으면 기능을 노출하지 않는다.
            if let split = settings.splitItem,
               allCategories.contains(where: { $0.id == split.categoryID }) {
                splitItem = split
            } else {
                splitItem = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 숫자만 남기고 앞자리 0과 과도한 길이를 정리한다.
    public func updateAmount(_ raw: String) {
        let filtered = raw.filter(\.isNumber)
        let trimmed = String(filtered.drop { $0 == "0" })
        amountDigits = String(trimmed.prefix(Self.maxDigits))
    }

    // MARK: - 키패드 입력

    public static let maxDigits = 12

    /// `1` 이나 `00` 처럼 한 번에 여러 자리를 붙일 수 있다.
    public func appendDigits(_ digits: String) {
        guard !digits.isEmpty else { return }
        // 아무것도 없을 때 `00` 을 누르면 0 만 쌓이므로 무시한다.
        if amountDigits.isEmpty, digits.allSatisfy({ $0 == "0" }) { return }
        updateAmount(amountDigits + digits)
    }

    public func deleteLastDigit() {
        guard !amountDigits.isEmpty else { return }
        amountDigits.removeLast()
    }

    public func clearAmount() {
        amountDigits = ""
    }

    @discardableResult
    public func save() async -> Bool {
        guard canSave, let categoryID else { return false }
        isSaving = true
        defer { isSaving = false }

        do {
            switch route {
            case .create:
                try await insertCreated(categoryID: categoryID)
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

    /// 분리가 켜져 있으면 두 건으로 나눠 넣는다. 나머지가 0 이면 분리분만 넣는다.
    /// 목록 맨 위에 원래 카테고리가 오도록 분리분을 먼저 넣는다.
    private func insertCreated(categoryID: UUID) async throws {
        // day 는 이미 달력일이므로 .gmt 로 정규화해야 값이 바뀌지 않는다
        func make(_ amount: Decimal, _ memo: String, _ category: UUID) -> Expense {
            Expense.make(
                amount: amount, memo: memo, categoryID: category,
                pickedDate: day, timeZone: .gmt
            )
        }

        guard let splitItem, isSplitting else {
            try await expenseRepository.insert(make(amount, memo, categoryID), at: 0)
            return
        }

        try await expenseRepository.insert(
            make(splitAmount, splitItem.memo(for: splitQuantity), splitItem.categoryID), at: 0
        )
        guard remainingAmount > .zero else { return }
        try await expenseRepository.insert(make(remainingAmount, memo, categoryID), at: 0)
    }

    private static func digits(from amount: Decimal) -> String {
        var rounded = Decimal()
        var value = amount
        NSDecimalRound(&rounded, &value, 0, .down)
        return NSDecimalNumber(decimal: rounded).stringValue
    }
}
