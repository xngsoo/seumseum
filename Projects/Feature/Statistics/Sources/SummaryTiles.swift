import SwiftUI
import DesignSystem
import Shared

/// 주기를 한눈에 보는 네 칸.
struct SummaryTiles: View {
    let summary: StatisticsSummary

    private let columns = [
        GridItem(.flexible(), spacing: 9),
        GridItem(.flexible(), spacing: 9)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 9) {
            tile(label: "총 지출", value: AmountFormatter.full(summary.total))
            tile(label: "일평균", value: AmountFormatter.full(summary.dailyAverage))
            tile(
                label: "최다 카테고리",
                value: summary.topCategory?.category.name ?? "—",
                tint: topCategoryTint
            )
            tile(label: "직전 주기 대비", value: changeText, tint: changeTint)
        }
    }

    private func tile(label: String, value: String, tint: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(AppFont.caption)
                .tracking(0.2)
                .foregroundStyle(AppColor.textFaint)
                .lineLimit(1)
            Text(value)
                .font(AppFont.tileValue)
                .foregroundStyle(tint ?? AppColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.lg - 2)
        .padding(.top, AppSpacing.lg - 2)
        .padding(.bottom, 13)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                .strokeBorder(AppColor.separator, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }

    /// 직전 주기 대비 증감률. 견줄 주기에 기록이 없으면 비율을 낼 수 없다.
    private var changeText: String {
        guard let ratio = summary.changeRatio else { return "—" }
        let percent = Int((ratio * 100).rounded())
        return (percent > 0 ? "+" : "") + "\(percent)%"
    }

    private var changeTint: Color? {
        guard let ratio = summary.changeRatio else { return AppColor.textFaint }
        let percent = Int((ratio * 100).rounded())
        if percent == 0 { return nil }
        return percent > 0 ? AppColor.trendUp : AppColor.trendDown
    }

    private var topCategoryTint: Color? {
        guard let top = summary.topCategory else { return AppColor.textFaint }
        return AppColor.category(top.category.colorToken)
    }
}

#Preview {
    SummaryTiles(summary: .empty)
        .padding(AppSpacing.screenMargin)
        .frame(maxHeight: .infinity)
        .background(AppColor.background)
}
