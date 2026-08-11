import SwiftUI
import UIKit

/// 편집을 시작할 때 커서를 텍스트 맨 끝으로 보내는 한 줄 텍스트 필드.
///
/// SwiftUI `TextField` 는 iOS 17 에서 커서 위치를 다룰 방법이 없다.
/// 오른쪽 정렬한 필드는 글자 왼쪽이 빈 공간이라, 탭한 지점에 커서를 놓는 기본 동작으로는
/// 이미 적힌 내용을 지우기 전에 커서를 끝으로 옮기는 일이 먼저 필요하다.
public struct CaretEndTextField: UIViewRepresentable {

    @Binding private var text: String
    private let placeholder: String
    private let font: UIFont
    private let textColor: UIColor
    private let alignment: NSTextAlignment
    private let onSubmit: () -> Void

    public init(
        _ placeholder: String,
        text: Binding<String>,
        font: UIFont = AppFont.uiRowTitle,
        textColor: UIColor = AppColor.uiTextPrimary,
        alignment: NSTextAlignment = .natural,
        onSubmit: @escaping () -> Void = {}
    ) {
        _text = text
        self.placeholder = placeholder
        self.font = font
        self.textColor = textColor
        self.alignment = alignment
        self.onSubmit = onSubmit
    }

    public func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator
        field.text = text
        field.borderStyle = .none
        field.backgroundColor = .clear
        field.returnKeyType = .done
        field.adjustsFontForContentSizeCategory = true
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textChanged(_:)),
            for: .editingChanged
        )
        apply(to: field)
        return field
    }

    public func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.parent = self
        // 입력 중인 값을 그대로 되돌려 넣으면 커서가 튀므로 실제로 다를 때만 반영한다.
        if field.text != text {
            field.text = text
        }
        apply(to: field)
    }

    /// HStack 에서 남는 폭을 모두 쓰도록 제안된 폭을 그대로 받는다.
    public func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView field: UITextField,
        context: Context
    ) -> CGSize? {
        let intrinsic = field.intrinsicContentSize
        let proposed = proposal.width ?? intrinsic.width
        return CGSize(width: proposed.isFinite ? proposed : intrinsic.width, height: intrinsic.height)
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func apply(to field: UITextField) {
        field.placeholder = placeholder
        field.font = font
        field.textColor = textColor
        field.textAlignment = alignment
    }

    @MainActor
    public final class Coordinator: NSObject, UITextFieldDelegate {

        fileprivate var parent: CaretEndTextField

        fileprivate init(_ parent: CaretEndTextField) {
            self.parent = parent
        }

        @objc fileprivate func textChanged(_ field: UITextField) {
            parent.text = field.text ?? ""
        }

        public func textFieldDidBeginEditing(_ field: UITextField) {
            // 탭 지점으로 커서를 놓는 기본 동작이 이 호출 뒤에 끝나므로, 한 틱 미뤄서 덮어쓴다.
            Task { @MainActor in
                let end = field.endOfDocument
                field.selectedTextRange = field.textRange(from: end, to: end)
            }
        }

        public func textFieldShouldReturn(_ field: UITextField) -> Bool {
            field.resignFirstResponder()
            parent.onSubmit()
            return true
        }
    }
}

#Preview {
    struct Preview: View {
        @State private var memo = "편의점 커피"

        var body: some View {
            HStack {
                Text("내용")
                    .font(AppFont.rowDetail)
                    .foregroundStyle(AppColor.textSecondary)
                CaretEndTextField("어디에 썼나요?", text: $memo, alignment: .right)
            }
            .padding(AppSpacing.md)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppSpacing.sm))
            .padding()
        }
    }

    return Preview()
}
