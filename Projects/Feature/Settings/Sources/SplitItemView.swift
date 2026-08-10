import SwiftUI
import DesignSystem
import Domain
import Shared

struct SplitItemView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: SplitItemViewModel

    private let onSave: (SplitItem?) -> Void

    init(
        initial: SplitItem?,
        categoryRepository: any CategoryRepository,
        onSave: @escaping (SplitItem?) -> Void
    ) {
        self.onSave = onSave
        _viewModel = State(
            initialValue: SplitItemViewModel(
                initial: initial, categoryRepository: categoryRepository
            )
        )
    }

    var body: some View {
        List {
            Section {
                Toggle("품목 분리 사용", isOn: $viewModel.isEnabled)
                    .tint(AppColor.accent)
            } footer: {
                Text("""
                한 번의 결제에 늘 같은 값의 품목이 섞여 들어올 때 씁니다. \
                지출을 추가할 때 수량만 넣으면 그만큼을 떼어 지정한 카테고리로 따로 기록합니다.
                """)
                .font(AppFont.caption)
            }
            .listRowBackground(AppColor.surface)

            if viewModel.isEnabled {
                detailSection
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppColor.background)
        .navigationTitle("품목 분리")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("저장") {
                    onSave(viewModel.result)
                    dismiss()
                }
                .disabled(!viewModel.canSave)
            }
        }
        .task { await viewModel.load() }
    }

    private var detailSection: some View {
        Section {
            LabeledContent("이름") {
                TextField("예: 담배", text: $viewModel.name)
                    .multilineTextAlignment(.trailing)
            }
            LabeledContent("개당 금액") {
                HStack(spacing: 2) {
                    TextField("0", text: unitAmountBinding)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .fixedSize()
                    Text("원")
                }
            }
            LabeledContent("수량 단위") {
                TextField("갑", text: $viewModel.unitLabel)
                    .multilineTextAlignment(.trailing)
            }
            Picker("분리될 카테고리", selection: categoryBinding) {
                ForEach(viewModel.categories) { category in
                    Text(category.name).tag(Optional(category.id))
                }
            }
        } header: {
            Text("규칙")
        } footer: {
            Text(example)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.accent)
        }
        .listRowBackground(AppColor.surface)
    }

    /// 지금 값으로 만들어지는 예시. 설정이 무엇을 하는지 숫자로 보여준다.
    private var example: String {
        guard let item = viewModel.result else { return "이름과 금액, 카테고리를 채워 주세요" }
        let categoryName = viewModel.categories.first { $0.id == item.categoryID }?.name ?? ""
        let two = item.amount(for: 2)
        return "예: 12,000원 결제에 \(item.name) 2\(item.unitLabel)을 입력하면 "
            + "\(categoryName) \(AmountFormatter.full(two)), 나머지 \(AmountFormatter.full(12_000 - two))"
    }

    private var unitAmountBinding: Binding<String> {
        Binding(
            get: { viewModel.groupedUnitAmount },
            set: { viewModel.updateUnitAmount($0) }
        )
    }

    private var categoryBinding: Binding<UUID?> {
        Binding(
            get: { viewModel.categoryID },
            set: { viewModel.categoryID = $0 }
        )
    }
}
