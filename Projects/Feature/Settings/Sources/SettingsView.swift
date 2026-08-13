import SwiftUI
import DesignSystem
import Domain
import Shared

public struct SettingsView: View {
    @Environment(AppNavigation.self) private var navigation
    @Environment(AppearanceStore.self) private var appearance
    @State private var viewModel: SettingsViewModel
    @State private var isCategoryListPresented = false
    @State private var isPaydayPresented = false

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
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    Text("설정")
                        .font(AppFont.screenTitle)
                        .foregroundStyle(AppColor.textPrimary)
                        .padding(.horizontal, AppSpacing.screenMargin)
                        .padding(.bottom, 0)

                    categorySection
                    payPeriodSection
                    appearanceSection
                    dataSection
                }
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.scrollBottomInset)
            }
            .scrollIndicators(.hidden)
            .background(AppColor.background)
            .bottomFadeOverlay()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $isCategoryListPresented) {
                CategoryListView(categoryRepository: categoryRepository)
            }
            .navigationDestination(isPresented: $isPaydayPresented) {
                PaydayView(viewModel: viewModel)
            }
            // 서브 화면이 덮고 있는 동안에는 탭바를 감춘다.
            // 미는 순간 이 화면에서 `onDisappear` 가 뒤따라 불리므로, 거기서 되돌리면
            // 탭바가 사라졌다 곧바로 다시 나타난다. 되돌리는 일은 탭이 바뀔 때 한다.
            .onChange(of: isCategoryListPresented || isPaydayPresented) { _, isPresented in
                navigation.isSubScreenPresented = isPresented
            }
            .task { await viewModel.load() }
            // 딤드 알럿은 fullScreenCover 로 뜬다. 한 뷰에 하나만 동작하므로 두 안내를 모은다.
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

    // MARK: - 기록

    private var categorySection: some View {
        SettingsSection("기록") {
            SettingsRow(
                "카테고리 관리",
                showsSeparator: false,
                showsChevron: true,
                action: { isCategoryListPresented = true }
            )
        }
    }

    // MARK: - 통계

    private var payPeriodSection: some View {
        SettingsSection("통계") {
            SettingsRow(
                "급여일",
                showsSeparator: false,
                showsChevron: true,
                action: { isPaydayPresented = true },
                trailing: { SettingsValue(text: viewModel.paydaySummary) }
            )
        } footer: {
            Text("급여일을 켜면 통계가 급여 주기 단위로 집계됩니다. 일별·월별 탭은 항상 달력 기준입니다.")
        }
    }

    // MARK: - 화면

    private var appearanceSection: some View {
        SettingsSection("화면") {
            SettingsRow("다크 모드") {
                Toggle("", isOn: darkModeBinding)
                    .labelsHidden()
                    .tint(AppColor.accent)
            }
            themePicker
        } footer: {
            Text("다크 모드를 끄면 시스템 설정과 무관하게 언제나 밝은 화면으로 보입니다.")
        }
    }

    /// 테마는 줄 하나에 네 칸으로 늘어놓는다. 색을 서로 견주며 고르는 자리라
    /// 목록으로 세우면 한 번에 볼 수 없다.
    private var themePicker: some View {
        HStack(spacing: 10) {
            ForEach(AppTheme.allCases, id: \.self) { theme in
                themeChip(theme)
            }
        }
        .padding(.horizontal, AppSpacing.screenMargin)
        .padding(.vertical, AppSpacing.lg - 2)
    }

    private func themeChip(_ theme: AppTheme) -> some View {
        let isSelected = viewModel.theme == theme

        return Button {
            select(theme)
        } label: {
            VStack(spacing: 7) {
                Circle()
                    .fill(AppColor.accent(of: theme))
                    .frame(width: 22, height: 22)
                Text(theme.displayName)
                    .font(AppFont.overline)
                    .foregroundStyle(isSelected ? AppColor.textPrimary : AppColor.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                isSelected ? AppColor.accentSoft(of: theme) : .clear,
                in: RoundedRectangle(cornerRadius: AppSpacing.md)
            )
            .overlay {
                RoundedRectangle(cornerRadius: AppSpacing.md)
                    .strokeBorder(
                        isSelected ? AppColor.accent(of: theme) : AppColor.separator,
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(theme.displayName)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    /// 토큰을 먼저 바꾸고 화면을 다시 그린 다음 저장한다.
    private func select(_ theme: AppTheme) {
        appearance.apply(theme: theme, isDarkMode: viewModel.isDarkMode)
        Task { await viewModel.setTheme(theme) }
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
        .padding(.bottom, AppSpacing.xs)
    }

    // MARK: - 안내 창

    private enum ActiveAlert {
        case resetConfirm
        case resetDone

        var title: String {
            switch self {
            case .resetConfirm: "모든 지출 기록을 지울까요?"
            case .resetDone: "삭제했습니다"
            }
        }

        var message: String {
            switch self {
            case .resetConfirm:
                "되돌릴 수 없습니다.\n카테고리와 설정은 그대로 남습니다."
            case .resetDone:
                "지출 기록을 모두 지웠습니다."
            }
        }

        var confirmTitle: String {
            switch self {
            case .resetDone: "확인"
            case .resetConfirm: "모두 삭제"
            }
        }

        var cancelTitle: String? {
            switch self {
            case .resetDone: nil
            case .resetConfirm: "취소"
            }
        }

        var isDestructive: Bool { self == .resetConfirm }
    }

    private var activeAlert: ActiveAlert? {
        if viewModel.isResetConfirmPresented { return .resetConfirm }
        if viewModel.isResetDonePresented { return .resetDone }
        return nil
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { activeAlert != nil },
            set: { isPresented in
                guard !isPresented else { return }
                viewModel.isResetConfirmPresented = false
                viewModel.isResetDonePresented = false
            }
        )
    }

    // MARK: - 바인딩

    private var darkModeBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isDarkMode },
            set: { isOn in
                appearance.apply(theme: viewModel.theme, isDarkMode: isOn)
                Task { await viewModel.setDarkMode(isOn) }
            }
        )
    }
}
