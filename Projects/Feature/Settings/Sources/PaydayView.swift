import SwiftUI
import DesignSystem
import Domain
import Shared

/// 급여일 설정. 통계 탭이 어느 구간을 한 주기로 볼지 정한다.
struct PaydayView: View {
    @Environment(\.dismiss) private var dismiss
    /// 설정 화면과 같은 인스턴스를 쓴다. 켜고 끈 결과가 두 화면에 함께 보여야 한다.
    let viewModel: SettingsViewModel

    private let dayColumns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 8)

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader("급여일", style: .subScreen, leading: .back("설정", { dismiss() }))

            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    enableSection
                    if viewModel.isPaydayEnabled {
                        daySection
                        adjustmentSection
                    }
                }
                .padding(.top, 18)
                .padding(.bottom, AppSpacing.xl * 2)
            }
            .scrollIndicators(.hidden)
        }
        .background(AppColor.background)
        .animation(.snappy(duration: 0.25), value: viewModel.isPaydayEnabled)
        .toolbar(.hidden, for: .navigationBar)
        .dimmedAlert(
            isPresented: noticeBinding,
            title: "통계 기준이 바뀝니다",
            message: "통계를 급여 주기 단위로 봅니다.\n이미 기록한 지출은 그대로이고, 묶어 보는 기준만 달라집니다.",
            confirmTitle: "확인"
        ) {}
    }

    // MARK: - 사용 여부

    private var enableSection: some View {
        SettingsSection {
            SettingsRow("급여 주기로 통계 보기", showsSeparator: false) {
                Toggle("", isOn: enabledBinding)
                    .labelsHidden()
                    .tint(AppColor.accent)
            }
        } footer: {
            Text("켜면 통계 탭이 달력상의 월 대신 급여일 기준 주기로 집계됩니다.\n일별·월별 탭과 기록 자체는 바뀌지 않습니다.")
        }
    }

    // MARK: - 지급일

    private var daySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("지급일")
            LazyVGrid(columns: dayColumns, spacing: 5) {
                ForEach(PaydayDay.pickerOptions, id: \.self) { day in
                    dayChip(day)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.lg - 2)
            .frame(maxWidth: .infinity)
            .background(AppColor.surface)
            .overlay(alignment: .top) { hairline }
            .overlay(alignment: .bottom) { hairline }

            Text(viewModel.previewCaption)
                .font(AppFont.rowCaption)
                .lineSpacing(3)
                .foregroundStyle(AppColor.textSecondary)
                .padding(.horizontal, AppSpacing.screenMargin)
                .padding(.top, 10)
        }
    }

    private func dayChip(_ day: PaydayDay) -> some View {
        let isSelected = viewModel.paydayDay == day

        return Button {
            Task { await viewModel.setPaydayDay(day) }
        } label: {
            Text(day.chipLabel)
                .font(AppFont.rowCaption)
                .foregroundStyle(isSelected ? Color.white : AppColor.textStrong)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(
                    isSelected ? AppColor.accent : AppColor.highlight,
                    in: RoundedRectangle(cornerRadius: 9)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - 주말 보정

    private var adjustmentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("지급일이 주말일 때")
            SegmentedControl(PaydayAdjustment.allCases, selection: adjustmentBinding) { $0.title }
                .padding(.horizontal, AppSpacing.lg)

            Text("주말(토·일)만 보정합니다. 공휴일은 판정하지 않으니 필요하면 주기 시작일을 직접 조정하세요.")
                .font(AppFont.caption)
                .lineSpacing(3)
                .foregroundStyle(AppColor.textFaint)
                .padding(.horizontal, AppSpacing.screenMargin)
                .padding(.top, 10)
        }
    }

    // MARK: - 뼈대

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(AppFont.caption)
            .tracking(1.2)
            .foregroundStyle(AppColor.textFaint)
            .padding(.horizontal, AppSpacing.screenMargin)
            .padding(.bottom, 9)
    }

    private var hairline: some View {
        Rectangle()
            .fill(AppColor.separator)
            .frame(height: 1)
    }

    // MARK: - 바인딩

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isPaydayEnabled },
            set: { enabled in Task { await viewModel.setPaydayEnabled(enabled) } }
        )
    }

    private var adjustmentBinding: Binding<PaydayAdjustment> {
        Binding(
            get: { viewModel.adjustment },
            set: { rule in Task { await viewModel.setAdjustment(rule) } }
        )
    }

    private var noticeBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isNoticePresented },
            set: { isPresented in
                guard !isPresented else { return }
                viewModel.isNoticePresented = false
            }
        )
    }
}

private extension PaydayDay {
    /// 칸에 들어가는 짧은 표기. 숫자는 숫자만 적는다.
    var chipLabel: String {
        switch self {
        case let .day(value): "\(value)"
        case .lastDay: "말일"
        }
    }
}
