import Charts
import SwiftUI
import DesignSystem
import Domain
import Shared

/// 카테고리별 몫. 도넛 가운데에 총액을 넣고 오른쪽에 범례를 세운다.
struct CategoryPieChart: View {
    let shares: [CategoryShare]
    let total: Decimal

    /// 범례에 세우는 최대 개수. 그보다 많으면 읽기보다 세기가 된다.
    /// 도넛에는 모든 카테고리가 그대로 들어간다. 줄이는 것은 범례뿐이다.
    private static let legendLimit = 4

    private let diameter: CGFloat = 132

    var body: some View {
        HStack(spacing: 22) {
            donut
            legend
        }
    }

    private var donut: some View {
        Chart(shares) { share in
            SectorMark(
                angle: .value("금액", doubleAmount(share)),
                innerRadius: .ratio(0.485)
            )
            .foregroundStyle(AppColor.category(share.category.colorToken))
        }
        .chartLegend(.hidden)
        .frame(width: diameter, height: diameter)
        .overlay { centerLabel }
        .accessibilityHidden(true)
    }

    private var centerLabel: some View {
        VStack(spacing: 1) {
            Text("TOTAL")
                .font(AppFont.overline)
                .tracking(0.8)
                .foregroundStyle(AppColor.textFaint)
            Text(AmountFormatter.shortValue(total))
                .font(AppFont.periodTitle)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, AppSpacing.xs)
    }

    /// 범례는 직접 그린다. 기본 범례는 색만 보여주고 비율을 못 담는다.
    private var legend: some View {
        VStack(alignment: .leading, spacing: 11) {
            // 도넛에는 다 있는데 목록에만 없으면 빠진 것처럼 보인다.
            // 도넛에는 다 있는데 목록에만 없으면 빠진 것처럼 보인다.
            if shares.count > legendShares.count {
                Text("지출 상위 \(legendShares.count)개")
                    .font(AppFont.overline)
                    .tracking(0.4)
                    .foregroundStyle(AppColor.textFaint)
            }
            ForEach(legendShares) { share in
                HStack(spacing: AppSpacing.sm) {
                    Circle()
                        .fill(AppColor.category(share.category.colorToken))
                        .frame(width: 7, height: 7)
                    Text(share.category.name)
                        .font(AppFont.rowCaption)
                        .foregroundStyle(AppColor.textStrong)
                        .lineLimit(1)
                    Spacer(minLength: AppSpacing.xs)
                    Text(percentText(share))
                        .font(AppFont.rowCaption)
                        .foregroundStyle(AppColor.textMuted)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    "\(share.category.name), \(percentText(share)), \(AmountFormatter.full(share.amount))"
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// 범례에 세울 몫. 이미 금액 내림차순이라 앞에서부터 자른다.
    /// 반올림해서 `0%` 가 되는 몫은 뺀다. 있으나 마나 한 값이 자리를 차지하고,
    /// 0% 라고 적힌 줄은 잘못 센 것처럼 보인다.
    private var legendShares: [CategoryShare] {
        Array(shares.filter { percent($0) > 0 }.prefix(Self.legendLimit))
    }

    private func doubleAmount(_ share: CategoryShare) -> Double {
        NSDecimalNumber(decimal: share.amount).doubleValue
    }

    private func percent(_ share: CategoryShare) -> Int {
        Int((share.ratio * 100).rounded())
    }

    private func percentText(_ share: CategoryShare) -> String {
        "\(percent(share))%"
    }
}

#Preview {
    let food = ExpenseCategory(name: "식비", symbolName: "fork.knife", colorToken: .orange)
    let cafe = ExpenseCategory(name: "카페·간식", symbolName: "cup.and.saucer", colorToken: .brown)
    let move = ExpenseCategory(name: "교통", symbolName: "bus", colorToken: .blue)
    let home = ExpenseCategory(name: "생활", symbolName: "house", colorToken: .green)
    let fun = ExpenseCategory(name: "문화", symbolName: "ticket", colorToken: .purple)

    return CategoryPieChart(
        shares: [
            CategoryShare(category: food, amount: 520_000, ratio: 0.52),
            CategoryShare(category: cafe, amount: 280_000, ratio: 0.28),
            CategoryShare(category: move, amount: 200_000, ratio: 0.20),
            CategoryShare(category: home, amount: 120_000, ratio: 0.12),
            CategoryShare(category: fun, amount: 80_000, ratio: 0.08)
        ],
        total: 1_000_000
    )
    .padding(AppSpacing.screenMargin)
    .frame(maxHeight: .infinity)
    .background(AppColor.background)
}
