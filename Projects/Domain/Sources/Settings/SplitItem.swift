import Foundation

/// 정액 품목 분리 규칙.
///
/// 한 번의 결제에 늘 같은 값의 품목이 섞여 들어올 때 쓴다.
/// 예: 편의점에서 담배 1갑(4,500원)과 간식을 함께 사면
/// 담배 몫만 담배 카테고리로 떼고 나머지를 편의점 카테고리에 남긴다.
public struct SplitItem: Hashable, Sendable {
    /// 품목 이름. 화면에 그대로 보인다. 예: `담배`
    public var name: String
    /// 개당 금액. 예: 4,500
    public var unitAmount: Decimal
    /// 떼어낸 금액이 들어갈 카테고리
    public var categoryID: UUID
    /// 수량 단위. 예: `갑`, `개`, `병`
    public var unitLabel: String

    public init(
        name: String,
        unitAmount: Decimal,
        categoryID: UUID,
        unitLabel: String = "개"
    ) {
        self.name = name
        self.unitAmount = unitAmount
        self.categoryID = categoryID
        self.unitLabel = unitLabel
    }

    /// 수량만큼의 분리 금액
    public func amount(for quantity: Int) -> Decimal {
        guard quantity > 0 else { return .zero }
        return unitAmount * Decimal(quantity)
    }

    /// 분리된 지출에 붙는 내용. 예: `담배 2갑`
    public func memo(for quantity: Int) -> String {
        "\(name) \(quantity)\(unitLabel)"
    }

    /// 총액에서 이 수량을 뗄 수 있는지. 뗀 금액이 총액을 넘으면 안 된다.
    public func canSplit(quantity: Int, from total: Decimal) -> Bool {
        quantity > 0 && amount(for: quantity) <= total
    }
}
