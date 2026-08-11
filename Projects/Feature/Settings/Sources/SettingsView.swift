import SwiftUI
import DesignSystem
import Domain
import Shared

public struct SettingsView: View {
    @Environment(AppNavigation.self) private var navigation
    @State private var viewModel: SettingsViewModel
    @State private var isCategoryListPresented = false

    private let categoryRepository: any CategoryRepository

    public init(
        settingsRepository: any SettingsRepository,
        categoryRepository: any CategoryRepository,
        dataResetting: any DataResetting
    ) {
        self.categoryRepository = categoryRepository
        _viewModel = State(
            initialValue: SettingsViewModel(
                settingsRepository: settingsRepository,
                dataResetting: dataResetting
            )
        )
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScreenHeader("설정")
                Divider().overlay(AppColor.separator)

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        categorySection
                        payPeriodSection
                        dataSection
                    }
                    .padding(.vertical, AppSpacing.lg)
                }
                .scrollIndicators(.hidden)
            }
            .background(AppColor.background)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $isCategoryListPresented) {
                CategoryListView(categoryRepository: categoryRepository)
            }
            .task { await viewModel.load() }
            // 딤드 알럿은 fullScreenCover 로 뜬다. 한 뷰에 여러 개 붙이면 하나만 동작하므로
            // 세 안내를 하나로 모아 띄운다. 셋은 동시에 뜰 일이 없다.
            .dimmedAlert(
                isPresented: alertBinding,
                title: activeAlert?.title ?? "",
                message: activeAlert?.message ?? "",
                confirmTitle: activeAlert?.confirmTitle ?? "확인",
                isDestructive: activeAlert?.isDestructive ?? false,
                cancelTitle: activeAlert?.cancelTitle
            ) {
                guard activeAlert == .resetConfirm else { return }
                Task {
                    await viewModel.resetAllExpenses()
                    navigation.dataDidChange()
                }
            }
        }
    }

    // MARK: - 분류

    /// 품목 분리는 보류 중이라 `FeatureFlag.splitItem` 이 켜질 때만 진입점을 둔다.
    private var categorySection: some View {
        SettingsSection("분류") {
            SettingsRow(
                "카테고리 관리",
                systemImage: "square.grid.2x2",
                showsSeparator: false,
                showsChevron: true,
                action: { isCategoryListPresented = true }
            )
        }
    }

    // MARK: - 급여 주기

    private var payPeriodSection: some View {
        SettingsSection("급여 주기") {
            SettingsRow("급여일 사용", showsSeparator: viewModel.isPaydayEnabled) {
                Toggle("", isOn: paydayBinding)
                    .labelsHidden()
                    .tint(AppColor.accent)
            }

            if viewModel.isPaydayEnabled {
                SettingsRow("급여일") {
                    menu(title: viewModel.paydayDay.title) {
                        Picker("급여일", selection: dayBinding) {
                            ForEach(PaydayDay.pickerOptions, id: \.self) { day in
                                Text(day.title).tag(day)
                            }
                        }
                    }
                }
                SettingsRow("지급일 보정", showsSeparator: false) {
                    menu(title: viewModel.adjustment.title) {
                        Picker("지급일 보정", selection: adjustmentBinding) {
                            ForEach(PaydayAdjustment.allCases, id: \.self) { rule in
                                Text(rule.title).tag(rule)
                            }
                        }
                    }
                }
            }
        } footer: {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(viewModel.previewCaption)
                    .foregroundStyle(AppColor.accent)
                Text("월급날을 기준으로 한 달을 묶어 통계를 봅니다.\n일별·달력 화면은 그대로 달력 기준입니다.")
            }
        }
    }

    private func menu(title: String, @ViewBuilder content: () -> some View) -> some View {
        Menu {
            content()
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppFont.rowDetail)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(AppColor.textSecondary)
        }
    }

    // MARK: - 데이터

    private var dataSection: some View {
        SettingsSection("데이터") {
            SettingsRow(
                "데이터 초기화",
                titleColor: AppColor.category(.red),
                showsSeparator: false,
                action: {
                    guard !viewModel.isResetting else { return }
                    viewModel.isResetConfirmPresented = true
                }
            ) {
                if viewModel.isResetting { ProgressView() }
            }
        } footer: {
            Text("지출 기록을 모두 지웁니다. 카테고리와 설정은 남습니다.")
        }
    }

    // MARK: - 안내 창

    private enum ActiveAlert {
        case paydayNotice
        case resetConfirm
        case resetDone

        var title: String {
            switch self {
            case .paydayNotice: "통계 기준이 바뀝니다"
            case .resetConfirm: "모든 지출 기록을 지울까요?"
            case .resetDone: "삭제했습니다"
            }
        }

        var message: String {
            switch self {
            case .paydayNotice:
                "통계를 급여 주기 단위로 봅니다.\n이미 기록한 지출은 그대로이고, 묶어 보는 기준만 달라집니다."
            case .resetConfirm:
                "되돌릴 수 없습니다.\n카테고리와 설정은 그대로 남습니다."
            case .resetDone:
                "지출 기록을 모두 지웠습니다."
            }
        }

        var confirmTitle: String {
            switch self {
            case .paydayNotice, .resetDone: "확인"
            case .resetConfirm: "모두 삭제"
            }
        }

        var cancelTitle: String? {
            switch self {
            case .paydayNotice, .resetDone: nil
            case .resetConfirm: "취소"
            }
        }

        var isDestructive: Bool { self == .resetConfirm }
    }

    private var activeAlert: ActiveAlert? {
        if viewModel.isNoticePresented { return .paydayNotice }
        if viewModel.isResetConfirmPresented { return .resetConfirm }
        if viewModel.isResetDonePresented { return .resetDone }
        return nil
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { activeAlert != nil },
            set: { isPresented in
                guard !isPresented else { return }
                viewModel.isNoticePresented = false
                viewModel.isResetConfirmPresented = false
                viewModel.isResetDonePresented = false
            }
        )
    }

    // MARK: - 바인딩

    private var paydayBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isPaydayEnabled },
            set: { enabled in Task { await viewModel.setPaydayEnabled(enabled) } }
        )
    }

    private var dayBinding: Binding<PaydayDay> {
        Binding(
            get: { viewModel.paydayDay },
            set: { day in Task { await viewModel.setPaydayDay(day) } }
        )
    }

    private var adjustmentBinding: Binding<PaydayAdjustment> {
        Binding(
            get: { viewModel.adjustment },
            set: { rule in Task { await viewModel.setAdjustment(rule) } }
        )
    }
}
