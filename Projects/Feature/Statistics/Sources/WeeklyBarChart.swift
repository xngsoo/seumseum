import SwiftUI
import DesignSystem
import Shared

/// 주기 안의 주차별 지출.
///
/// 막대 위에 금액, 아래에 주차를 적고 가장 큰 주만 액센트로 세운다.
/// 축과 눈금 없이 서로 견주기만 하는 그림이라 막대를 직접 그린다.
struct WeeklyBarChart: View {
    let weeks: [WeeklyTotal]

    /// 가장 큰 막대의 높이.
    private let maxBarHeight: CGFloat = 74
    /// 기록이 없는 주에도 남기는 최소 높이. 자리가 비어 보이지 않게 한다.
    private let minBarHeight: CGFloat = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("WEEKLY")
                .font(AppFont.overline)
                .tracking(1.2)
                .foregroundStyle(AppColor.textFaint)
                .padding(.bottom, AppSpacing.lg)

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(weeks) { week in
                    column(week)
                }
            }
        }
    }

    private func column(_ week: WeeklyTotal) -> some View {
        VStack(spacing: AppSpacing.sm) {
            Text(AmountFormatter.shortValue(week.amount))
                .font(AppFont.calendarAmount)
                .foregroundStyle(AppColor.textMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            UnevenRoundedRectangle(
                topLeadingRadius: 6, bottomLeadingRadius: 3,
                bottomTrailingRadius: 3, topTrailingRadius: 6
            )
            .fill(isPeak(week) ? AppColor.accent : AppColor.accentSoft)
            .frame(height: height(week))
            Text(week.label)
                .font(AppFont.calendarAmount)
                .foregroundStyle(AppColor.textFaint)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(week.label), \(AmountFormatter.full(week.amount))")
    }

    private func height(_ week: WeeklyTotal) -> CGFloat {
        let peak = weeks.map(\.amount).max() ?? .zero
        guard peak > .zero else { return minBarHeight }
        let ratio = NSDecimalNumber(decimal: week.amount).doubleValue
            / NSDecimalNumber(decimal: peak).doubleValue
        return max(minBarHeight, maxBarHeight * ratio)
    }

    /// 가장 많이 쓴 주. 같은 금액이 둘이면 둘 다 세운다.
    private func isPeak(_ week: WeeklyTotal) -> Bool {
        guard let peak = weeks.map(\.amount).max(), peak > .zero else { return false }
        return week.amount == peak
    }
}

#Preview {
    let day = CalendarDay.today()

    return WeeklyBarChart(weeks: [
        WeeklyTotal(week: 1, range: day ..< CalendarDay.adding(days: 7, to: day), amount: 320_000),
        WeeklyTotal(week: 2, range: day ..< CalendarDay.adding(days: 7, to: day), amount: 540_000),
        WeeklyTotal(week: 3, range: day ..< CalendarDay.adding(days: 7, to: day), amount: 120_000),
        WeeklyTotal(week: 4, range: day ..< CalendarDay.adding(days: 7, to: day), amount: .zero)
    ])
    .padding(AppSpacing.screenMargin)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(AppColor.background)
}
