import SwiftUI

/// 어두워진 배경 위에 뜨는 확인 창. 시스템 `alert` 대신 앱 색과 서체를 그대로 쓴다.
///
/// `overlay` 가 아니라 배경이 비치는 `fullScreenCover` 로 띄운다.
/// 그래야 탭바까지 화면 전체가 어두워진다. 대신 밀려 올라오는 기본 연출은 끄고
/// 안에서 직접 페이드로 띄운다.
private struct DimmedAlert: ViewModifier {

    @Binding var isPresented: Bool
    let title: String
    let message: String
    let confirmTitle: String
    let isDestructive: Bool
    /// nil 이면 버튼이 하나뿐인 안내 창이 된다.
    let cancelTitle: String?
    let onConfirm: () -> Void

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented) {
                AlertLayer(
                    title: title,
                    message: message,
                    confirmTitle: confirmTitle,
                    isDestructive: isDestructive,
                    cancelTitle: cancelTitle,
                    onCancel: { isPresented = false },
                    onConfirm: {
                        // 닫기보다 먼저 부른다. 창을 닫는 쪽이 취소로 취급돼
                        // 확인에 필요한 상태를 지워버릴 수 있다.
                        onConfirm()
                        isPresented = false
                    }
                )
                .presentationBackground(.clear)
            }
            // 뜨고 지는 순간에만 기본 연출을 끈다. 값을 지정하지 않으면
            // 이 뷰 아래 전체의 애니메이션이 함께 꺼진다.
            .transaction(value: isPresented) { $0.disablesAnimations = true }
    }
}

private struct AlertLayer: View {
    let title: String
    let message: String
    let confirmTitle: String
    let isDestructive: Bool
    let cancelTitle: String?
    let onCancel: () -> Void
    let onConfirm: () -> Void

    @State private var isVisible = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)

            card
                .padding(.horizontal, AppSpacing.xl)
                .scaleEffect(isVisible ? 1 : 0.94)
        }
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.snappy(duration: 0.18)) { isVisible = true }
        }
    }

    private var card: some View {
        VStack(spacing: 0) {
            VStack(spacing: AppSpacing.sm) {
                Text(title)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(AppFont.rowDetail)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.xl)

            Divider().overlay(AppColor.separator)

            HStack(spacing: 0) {
                if let cancelTitle {
                    button(cancelTitle, tint: AppColor.textSecondary, action: onCancel)
                    Divider().overlay(AppColor.separator)
                }
                button(
                    confirmTitle,
                    tint: isDestructive ? AppColor.category(.red) : AppColor.accent,
                    action: onConfirm
                )
            }
            .frame(height: 48)
        }
        .frame(maxWidth: 320)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppSpacing.lg))
    }

    private func button(_ title: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.rowTitle)
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

public extension View {
    /// 배경을 어둡게 깔고 확인 창을 띄운다. 바깥을 누르면 취소로 닫힌다.
    /// `cancelTitle` 을 nil 로 두면 버튼이 하나뿐인 안내 창이 된다.
    func dimmedAlert(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        confirmTitle: String,
        isDestructive: Bool = false,
        cancelTitle: String? = "취소",
        onConfirm: @escaping () -> Void = {}
    ) -> some View {
        modifier(
            DimmedAlert(
                isPresented: isPresented,
                title: title,
                message: message,
                confirmTitle: confirmTitle,
                isDestructive: isDestructive,
                cancelTitle: cancelTitle,
                onConfirm: onConfirm
            )
        )
    }
}

#Preview {
    struct Preview: View {
        @State private var isPresented = false

        var body: some View {
            Button("열기") { isPresented = true }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColor.background)
                .dimmedAlert(
                    isPresented: $isPresented,
                    title: "‘식비’를 삭제할까요?",
                    message: "이 카테고리로 기록한 지출 3건도 함께 지워집니다.\n되돌릴 수 없습니다.",
                    confirmTitle: "삭제",
                    isDestructive: true
                ) {}
        }
    }

    return Preview()
}
