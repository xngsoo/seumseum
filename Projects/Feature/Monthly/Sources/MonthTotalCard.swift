import SwiftUI
import DesignSystem
import Shared

/// 달력 아래에 고정되는 그달 요약. 달력이 6줄까지 늘어나도 자리가 바뀌지 않는다.
///
/// 세 줄을 언제나 그린다. 견줄 것이 없다고 줄을 빼면 달을 넘길 때마다 카드 높이가
/// 달라져서, 고정해 둔 카드가 위아래로 흔들린다. 값이 없는 자리는 줄표로 채운다.
struct MonthTotalCard: View {
    let total: Decimal
    let comparison: MonthComparison?

    private let placeholder = "—"

    var body: some View {
        VStack(spacing: 0) {
            totalRow
            Rectangle()
                .fill(AppColor.separatorFaint)
                .frame(height: 1)
                .padding(.vertical, AppSpacing.md)
            periodRow
            deltaRow
                .padding(.top, AppSpacing.sm)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, 18)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppSpacing.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: AppSpacing.cardRadius)
                .strokeBorder(AppColor.separator, lineWidth: 1)
        }
    }

    // MARK: - 줄

    private var totalRow: some View {
        row(label: totalLabel) {
            amount(total, font: AppFont.amountMedium, color: AppColor.textPrimary)
        }
        .accessibilityLabel("\(totalLabel) \(AmountFormatter.full(total))")
    }

    /// 이번 달은 아직 끝나지 않았으므로 견준 구간을 함께 적는다.
    private var periodRow: some View {
        row(label: periodLabel, detail: comparison?.periodText ?? placeholder) {
            if let comparison {
                amount(comparison.currentTotal, font: AppFont.amount, color: AppColor.textStrong)
            } else {
                Text(placeholder)
                    .font(AppFont.amount)
                    .foregroundStyle(AppColor.textFaint)
            }
        }
    }

    private var deltaRow: some View {
        row(label: "지난달 같은 기간 대비") {
            deltaValue
        }
        .accessibilityLabel(deltaAccessibilityText)
    }

    /// 값은 어느 갈래든 `AppFont.amount` 로 쓴다. 줄 높이는 그 줄에서 가장 큰 글꼴이
    /// 정하므로, 여기서 더 작은 글꼴을 쓰면 그 달에서만 카드가 낮아진다.
    /// 비교할 것이 없으면 문장 대신 줄표를 둔다. 사연은 왼쪽 이름이 이미 말하고 있다.
    @ViewBuilder
    private var deltaValue: some View {
        if let percent = comparison?.deltaPercent {
            HStack(spacing: 3) {
                Image(systemName: percent > 0 ? "arrow.up" : "arrow.down")
                    .font(.system(size: 10, weight: .semibold))
                Text("\(abs(percent))%")
                    .font(AppFont.amount)
            }
            .foregroundStyle(percent > 0 ? AppColor.trendUp : AppColor.trendDown)
        } else {
            Text(placeholder)
                .font(AppFont.amount)
                .foregroundStyle(AppColor.textFaint)
        }
    }

    // MARK: - 뼈대

    /// 왼쪽 이름, 오른쪽 값. 줄 높이를 한 곳에서 맞춘다.
    private func row(
        label: String,
        detail: String? = nil,
        @ViewBuilder value: () -> some View
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
            Text(label)
                .font(AppFont.rowCaption)
                .foregroundStyle(AppColor.textMuted)
                .lineLimit(1)
            if let detail {
                Text(detail)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textFaint)
                    .lineLimit(1)
            }
            Spacer(minLength: AppSpacing.xs)
            value()
        }
        .accessibilityElement(children: .combine)
    }

    private func amount(_ value: Decimal, font: Font, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(AmountFormatter.grouped(value))
                .font(font)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("원")
                .font(AppFont.rowDetail)
                .foregroundStyle(AppColor.textMuted)
        }
    }

    // MARK: - 문구

    private var totalLabel: String {
        comparison?.isCurrentMonth == false ? "총액" : "이번 달 총액"
    }

    private var periodLabel: String {
        comparison?.isCurrentMonth == false ? "비교 기간" : "오늘까지"
    }

    private var deltaAccessibilityText: String {
        guard let comparison else { return "지난달과 비교하지 못했습니다" }
        guard let percent = comparison.deltaPercent else {
            return "지난달 같은 기간에는 기록이 없습니다"
        }
        let direction = percent > 0 ? "늘었습니다" : "줄었습니다"
        return "지난달 같은 기간 대비 \(abs(percent))퍼센트 \(direction)"
    }
}

#Preview {
    VStack(spacing: AppSpacing.lg) {
        MonthTotalCard(
            total: 1_535_000,
            comparison: MonthComparison(
                periodText: "8/1 – 8/13",
                currentTotal: 191_750,
                previousTotal: 170_000,
                deltaPercent: 13,
                isCurrentMonth: true
            )
        )
        MonthTotalCard(
            total: 1_535_000,
            comparison: MonthComparison(
                periodText: "7/1 – 7/31",
                currentTotal: 1_535_000,
                previousTotal: .zero,
                deltaPercent: nil,
                isCurrentMonth: false
            )
        )
        MonthTotalCard(total: .zero, comparison: nil)
    }
    .padding(AppSpacing.xl)
    .frame(maxHeight: .infinity)
    .background(AppColor.background)
}
