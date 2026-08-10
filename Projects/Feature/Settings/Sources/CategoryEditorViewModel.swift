import Foundation
import Observation
import Domain
import Shared

@MainActor
@Observable
public final class CategoryEditorViewModel {

    public enum Mode: Hashable, Sendable, Identifiable {
        case create(nextIndex: Int)
        case edit(ExpenseCategory)

        public var id: String {
            switch self {
            case let .create(index): "create-\(index)"
            case let .edit(category): "edit-\(category.id.uuidString)"
            }
        }
    }

    public var name: String
    public var symbolName: String
    public var colorToken: ColorToken

    public private(set) var errorMessage: String?
    public var isErrorPresented = false

    private let mode: Mode
    private let categoryRepository: any CategoryRepository

    public init(mode: Mode, categoryRepository: any CategoryRepository) {
        self.mode = mode
        self.categoryRepository = categoryRepository

        switch mode {
        case .create:
            name = ""
            symbolName = CategorySymbols.all.first ?? "tag.fill"
            colorToken = .orange
        case let .edit(category):
            name = category.name
            symbolName = category.symbolName
            colorToken = category.colorToken
        }
    }

    public var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    public var title: String { isEditing ? "카테고리 수정" : "카테고리 추가" }

    /// 기본 카테고리도 이름·색·아이콘은 바꿀 수 있다. 삭제만 막힌다.
    public var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @discardableResult
    public func save() async -> Bool {
        guard canSave else { return false }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            switch mode {
            case let .create(nextIndex):
                try await categoryRepository.insert(
                    ExpenseCategory(name: trimmed, symbolName: symbolName, colorToken: colorToken),
                    at: nextIndex
                )
            case let .edit(original):
                var edited = original
                edited.name = trimmed
                edited.symbolName = symbolName
                edited.colorToken = colorToken
                try await categoryRepository.update(edited)
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            isErrorPresented = true
            return false
        }
    }
}

/// 카테고리에 쓸 수 있는 아이콘 목록. 앱이 고른 것만 노출해 임의 문자열이 들어가지 않게 한다.
public enum CategorySymbols {
    public static let all: [String] = [
        "fork.knife", "cup.and.saucer.fill", "bus.fill", "car.fill",
        "bag.fill", "cart.fill", "house.fill", "wifi",
        "cross.case.fill", "pills.fill", "ticket.fill", "gamecontroller.fill",
        "book.fill", "graduationcap.fill", "airplane", "gift.fill",
        "pawprint.fill", "scissors", "creditcard.fill", "phone.fill",
        "dumbbell.fill", "leaf.fill", "wrench.and.screwdriver.fill", "ellipsis.circle.fill",
    ]
}
