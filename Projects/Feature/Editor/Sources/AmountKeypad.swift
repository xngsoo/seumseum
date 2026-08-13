import SwiftUI
import DesignSystem

/// 금액 전용 키패드.
///
/// 시스템 키보드를 쓰지 않는 이유는 높이를 우리가 정할 수 없기 때문이다.
/// 직접 그리면 화면에 무엇이 보일지 통제할 수 있고, 가계부에서 자주 쓰는 `00` 키도 넣을 수 있다.
struct AmountKeypad: View {

    let onDigits: (String) -> Void
    let onDelete: () -> Void
    let onClear: () -> Void

    private let keys: [Key] = [
        .digits("1"), .digits("2"), .digits("3"),
        .digits("4"), .digits("5"), .digits("6"),
        .digits("7"), .digits("8"), .digits("9"),
        .digits("00"), .digits("0"), .delete
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)

    private enum Key: Hashable {
        case digits(String)
        case delete
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(keys, id: \.self) { key in
                button(key)
            }
        }
    }

    @ViewBuilder
    private func button(_ key: Key) -> some View {
        switch key {
        case let .digits(value):
            keyButton(
                label: Text(value).font(.system(size: 23, weight: .medium)),
                background: AppColor.surface
            ) {
                onDigits(value)
            }
            .accessibilityLabel(value)
        case .delete:
            keyButton(
                label: Image(systemName: "delete.left").font(.system(size: 19)),
                background: AppColor.highlight
            ) {
                onDelete()
            }
            // 길게 누르면 전체 삭제. 한 자리씩 지우는 것보다 빠르다.
            .simultaneousGesture(LongPressGesture().onEnded { _ in onClear() })
            .accessibilityLabel("지우기")
            .accessibilityHint("길게 누르면 모두 지웁니다")
        }
    }

    private func keyButton(
        label: some View, background: Color, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            label
                .foregroundStyle(AppColor.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(background, in: RoundedRectangle(cornerRadius: AppSpacing.sm))
                // 아래로 한 줄 그림자를 두어 키가 판에서 떠 보이게 한다.
                .shadow(color: AppColor.separatorStrong, radius: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        Spacer()
        AmountKeypad(onDigits: { _ in }, onDelete: {}, onClear: {})
            .padding(5)
    }
    .background(AppColor.surfaceSunken)
}
