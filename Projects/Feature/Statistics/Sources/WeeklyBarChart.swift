import Charts
import SwiftUI
import DesignSystem
import Shared

struct WeeklyBarChart: View {
    let weeks: [WeeklyTotal]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("주차별")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)

            Chart(weeks) { week in
                BarMark(
                    x: .value("주차", week.label),
                    y: .value("금액", NSDecimalNumber(decimal: week.amount).doubleValue)
                )
                .cornerRadius(4)
                .foregroundStyle(AppColor.accent)
                .accessibilityLabel(week.label)
                .accessibilityValue(AmountFormatter.full(week.amount))
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine().foregroundStyle(AppColor.separator)
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(AmountFormatter.short(Decimal(amount)))
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            .frame(height: 160)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
    }
}
