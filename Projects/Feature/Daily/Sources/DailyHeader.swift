import SwiftUI
import DesignSystem
import Shared

/// 탭 1 상단. 목록과 함께 스크롤된다.
struct DailyHeader: View {
    let day: Date
    let total: Decimal
    let isToday: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToday: () -> Void

    /// 날짜 행과 총액 사이의 간격. `오늘로` 버튼이 들어갈 자리이기도 하다.
    private let shortcutSlotHeight: CGFloat = 34

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            dayRow
            shortcutSlot
            totalBlock
            Rectangle()
                .fill(AppColor.separatorStrong)
                .frame(height: 1)
                .padding(.top, 22)
        }
    }

    private var dayRow: some View {
        HStack(spacing: AppSpacing.sm) {
            stepButton(systemImage: "chevron.left", label: "이전 날짜", action: onPrevious)
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Text(CalendarDay.dayText(day))
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.textPrimary)
                Text(CalendarDay.weekdayText(day))
                    .font(AppFont.rowDetail)
                    .foregroundStyle(AppColor.textMuted)
            }
            Spacer()
            stepButton(systemImage: "chevron.right", label: "다음 날짜", action: onNext)
        }
        .frame(height: 34)
    }

    /// 버튼이 있든 없든 같은 높이를 차지한다.
    /// 세로 흐름에 끼워 넣으면 버튼이 생길 때마다 아래의 구분선이 밀려 내려간다.
    private var shortcutSlot: some View {
        ZStack {
            if !isToday {
                todayShortcut
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: shortcutSlotHeight)
    }

    private var todayShortcut: some View {
        Button(action: onToday) {
            Text("오늘로")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.accentInk)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, 5)
                .background(AppColor.accentSoft, in: Capsule())
        }
        .buttonStyle(.plain)
        // 날짜가 바뀌며 나타나고 사라진다. 자리를 밀어내지 않도록 흐리게만 바꾼다.
        .transition(.opacity)
    }

    private var totalBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TOTAL")
                .font(AppFont.overline)
                .tracking(1.4)
                .foregroundStyle(AppColor.textFaint)
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xs) {
                Text(AmountFormatter.grouped(total))
                    .font(AppFont.amountHero)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text("원")
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textMuted)
            }
        }
        // 위쪽 간격은 `shortcutSlot` 이 이미 만들어 둔다.
        .accessibilityElement(children: .combine)
        .accessibilityLabel("합계 \(AmountFormatter.full(total))")
    }

    private func stepButton(
        systemImage: String, label: String, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppColor.textFaint)
                .frame(width: 34, height: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

#Preview {
    VStack {
        DailyHeader(
            day: CalendarDay.today(),
            total: 152_300,
            isToday: false,
            onPrevious: {},
            onNext: {},
            onToday: {}
        )
        .padding(.horizontal, AppSpacing.screenMargin)
        Spacer()
    }
    .background(AppColor.background)
}
