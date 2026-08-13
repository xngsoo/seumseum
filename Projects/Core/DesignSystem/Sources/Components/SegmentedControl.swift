import SwiftUI

/// 몇 안 되는 선택지를 한 줄에 늘어놓는 고르개.
/// 고른 칸만 바닥이 떠오른다. 시스템 `Picker(.segmented)` 는 색과 높이를 우리가 정할 수 없다.
public struct SegmentedControl<Value: Hashable>: View {
    private let values: [Value]
    private let label: (Value) -> String
    @Binding private var selection: Value

    public init(
        _ values: [Value],
        selection: Binding<Value>,
        label: @escaping (Value) -> String
    ) {
        self.values = values
        _selection = selection
        self.label = label
    }

    public var body: some View {
        HStack(spacing: 3) {
            ForEach(values, id: \.self) { value in
                option(value)
            }
        }
        .padding(3)
        .background(AppColor.separatorFaint, in: RoundedRectangle(cornerRadius: 11))
    }

    private func option(_ value: Value) -> some View {
        let isSelected = selection == value

        return Button {
            selection = value
        } label: {
            Text(label(value))
                .font(AppFont.rowCaption)
                .foregroundStyle(isSelected ? AppColor.textPrimary : AppColor.textMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                // 어두운 화면에서는 그림자가 보이지 않아, 고른 칸이 떠 보이려면
                // 바닥을 한 단계 더 밝게 깔고 테두리로 경계를 그어야 한다.
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(AppColor.surfaceRaised)
                            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                            .overlay {
                                RoundedRectangle(cornerRadius: 9)
                                    .strokeBorder(AppColor.separatorStrong, lineWidth: 1)
                            }
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label(value))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    @Previewable @State var selection = "숫자"

    return SegmentedControl(["숫자", "분류", "상세"], selection: $selection) { $0 }
        .padding()
        .background(AppColor.background)
}
