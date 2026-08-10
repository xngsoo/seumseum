import Charts
import SwiftUI
import DesignSystem
import Shared

struct CategoryPieChart: View {
    let shares: [CategoryShare]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("카테고리별")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)

            Chart(shares) { share in
                SectorMark(
                    angle: .value("금액", doubleAmount(share)),
                    innerRadius: .ratio(0.58),
                    angularInset: 1.5
                )
                .cornerRadius(3)
                .foregroundStyle(AppColor.category(share.category.colorToken))
            }
            .chartLegend(.hidden)
            .frame(height: 200)

            legend
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
    }

    /// 범례는 직접 그린다. 기본 범례는 색만 보여주고 금액·비율을 못 담는다.
    private var legend: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(shares) { share in
                HStack(spacing: AppSpacing.sm) {
                    Circle()
                        .fill(AppColor.category(share.category.colorToken))
                        .frame(width: 10, height: 10)
                    Text(share.category.name)
                        .font(AppFont.rowDetail)
                        .foregroundStyle(AppColor.textPrimary)
                    Text(percentText(share))
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                    Spacer(minLength: AppSpacing.sm)
                    Text(AmountFormatter.short(share.amount))
                        .font(AppFont.amount)
                        .foregroundStyle(AppColor.textPrimary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    "\(share.category.name), \(percentText(share)), \(AmountFormatter.full(share.amount))"
                )
            }
        }
    }

    private func doubleAmount(_ share: CategoryShare) -> Double {
        NSDecimalNumber(decimal: share.amount).doubleValue
    }

    private func percentText(_ share: CategoryShare) -> String {
        "\(Int((share.ratio * 100).rounded()))%"
    }
}
