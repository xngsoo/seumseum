import SwiftUI
import DesignSystem
import Shared

struct DailyHeader: View {
    let day: Date
    let total: Decimal

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(CalendarDay.headerText(day))
                .font(AppFont.screenTitle)
                .foregroundStyle(AppColor.textPrimary)
            Text(AmountFormatter.full(total))
                .font(AppFont.amountLarge)
                .foregroundStyle(AppColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.screenMargin)
        .padding(.vertical, AppSpacing.lg)
        .background(AppColor.surface)
    }
}

#Preview {
    DailyHeader(day: CalendarDay.today(), total: 152_300)
}
