import SwiftUI
import DesignSystem
import Shared

struct SummaryTiles: View {
    let summary: StatisticsSummary

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.sm),
        GridItem(.flexible(), spacing: AppSpacing.sm),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
            tile(title: "일평균", value: AmountFormatter.short(summary.dailyAverage))
            tile(title: "최다 사용", value: summary.topCategory?.category.name ?? "없음")
            tile(title: "직전 주기 대비", value: changeText, tint: changeTint)
            tile(title: "기록", value: "\(summary.weeklyTotals.count)주")
        }
    }

    private func tile(title: String, value: String, tint: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
            Text(value)
                .font(AppFont.amount)
                .foregroundStyle(tint ?? AppColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
    }

    private var changeText: String {
        guard summary.hasComparison else { return "비교 없음" }
        let sign = summary.change >= .zero ? "+" : "-"
        return sign + AmountFormatter.short(abs(summary.change))
    }

    private var changeTint: Color? {
        guard summary.hasComparison, summary.change != .zero else { return nil }
        return summary.change > .zero ? AppColor.category(.red) : AppColor.category(.green)
    }
}
