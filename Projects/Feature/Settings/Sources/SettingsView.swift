import SwiftUI
import DesignSystem
import Domain
import Shared

public struct SettingsView: View {
    @Environment(AppNavigation.self) private var navigation
    @State private var viewModel: SettingsViewModel

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
            List {
                categorySection
                payPeriodSection
                //comingSoonSection
                dataSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .navigationTitle("설정")
            .task { await viewModel.load() }
            .alert("통계 기준이 바뀝니다", isPresented: $viewModel.isNoticePresented) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("통계를 급여 주기 단위로 봅니다. 이미 기록한 지출은 그대로이고, 묶어 보는 기준만 달라집니다.")
            }
            .confirmationDialog(
                "모든 지출 기록을 지울까요?",
                isPresented: $viewModel.isResetConfirmPresented,
                titleVisibility: .visible
            ) {
                Button("모두 삭제", role: .destructive) {
                    Task {
                        await viewModel.resetAllExpenses()
                        navigation.dataDidChange()
                    }
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("되돌릴 수 없습니다. 카테고리와 설정은 그대로 남습니다.")
            }
            .alert("삭제했습니다", isPresented: $viewModel.isResetDonePresented) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("지출 기록을 모두 지웠습니다.")
            }
        }
    }

    private var payPeriodSection: some View {
        Section {
            Toggle("급여일 사용", isOn: paydayBinding)
                .tint(AppColor.accent)

            if viewModel.isPaydayEnabled {
                Picker("급여일", selection: dayBinding) {
                    ForEach(PaydayDay.pickerOptions, id: \.self) { day in
                        Text(day.title).tag(day)
                    }
                }
                Picker("지급일 보정", selection: adjustmentBinding) {
                    ForEach(PaydayAdjustment.allCases, id: \.self) { rule in
                        Text(rule.title).tag(rule)
                    }
                }
            }
        } header: {
            Text("급여 주기")
        } footer: {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(viewModel.previewCaption)
                    .foregroundStyle(AppColor.accent)
                Text("월급날을 기준으로 한 달을 묶어 통계를 봅니다. 일별·달력 화면은 그대로 달력 기준입니다.")
            }
            .font(AppFont.caption)
        }
        .listRowBackground(AppColor.surface)
    }

    private var categorySection: some View {
        Section("분류") {
            NavigationLink {
                CategoryListView(categoryRepository: categoryRepository)
            } label: {
                Label("카테고리 관리", systemImage: "square.grid.2x2")
            }

            NavigationLink {
                SplitItemView(
                    initial: viewModel.splitItem,
                    categoryRepository: categoryRepository,
                    onSave: { item in Task { await viewModel.setSplitItem(item) } }
                )
            } label: {
                LabeledContent {
                    Text(viewModel.splitSummary)
                        .font(AppFont.rowDetail)
                        .foregroundStyle(AppColor.textSecondary)
                } label: {
                    Label("품목 분리", systemImage: "arrow.triangle.branch")
                }
            }
        }
        .listRowBackground(AppColor.surface)
    }

    private var comingSoonSection: some View {
        Section("준비 중") {
            ForEach(["통화 표시", "기록 리마인더", "CSV 내보내기", "앱 잠금"], id: \.self) { title in
                HStack {
                    Text(title)
                        .foregroundStyle(AppColor.textSecondary)
                    Spacer()
                    Text("곧 지원")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
        }
        .listRowBackground(AppColor.surface)
    }

    private var dataSection: some View {
        Section {
            Button(role: .destructive) {
                viewModel.isResetConfirmPresented = true
            } label: {
                HStack {
                    Text("데이터 초기화")
                    Spacer()
                    if viewModel.isResetting { ProgressView() }
                }
            }
            .disabled(viewModel.isResetting)
        } header: {
            Text("데이터")
        } footer: {
            Text("지출 기록을 모두 지웁니다. 카테고리와 설정은 남습니다.")
                .font(AppFont.caption)
        }
        .listRowBackground(AppColor.surface)
    }

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
