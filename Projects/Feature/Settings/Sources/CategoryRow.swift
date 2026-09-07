import SwiftUI
import DesignSystem
import Domain

/// 카테고리 관리 화면의 한 줄.
/// 줄을 누르면 이름·색·아이콘을 고치고, 오른쪽 버튼으로 순서와 삭제를 다룬다.
struct CategoryRow: View {
    let category: ExpenseCategory
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onEdit: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 11) {
            icon
            Text(category.name)
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(category.isBuiltIn ? "기본" : "추가")
                .font(AppFont.overline)
                .tracking(0.4)
                .foregroundStyle(AppColor.textDim)
            Spacer(minLength: AppSpacing.xs)
            controls
        }
        .padding(.leading, AppSpacing.screenMargin)
        .padding(.trailing, 18)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(category.name), \(category.isBuiltIn ? "기본" : "추가") 카테고리")
        .accessibilityAction(named: "수정") { onEdit() }
        .accessibilityAction(named: "위로 이동") { if canMoveUp { onMoveUp() } }
        .accessibilityAction(named: "아래로 이동") { if canMoveDown { onMoveDown() } }
        .accessibilityAction(named: "삭제") { onDelete() }
    }

    private var icon: some View {
        Image(systemName: category.symbolName)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(AppColor.category(category.colorToken))
            .frame(width: 30, height: 30)
            .background(AppColor.categorySoft(category.colorToken), in: Circle())
    }

    /// 순서와 삭제. 손짓 대신 버튼으로 다뤄서 VoiceOver 로도 같은 일을 할 수 있다.
    private var controls: some View {
        HStack(spacing: 0) {
            control(systemImage: "arrow.up", label: "위로 이동", isEnabled: canMoveUp, action: onMoveUp)
            control(systemImage: "arrow.down", label: "아래로 이동", isEnabled: canMoveDown, action: onMoveDown)
            control(
                systemImage: "xmark",
                label: "삭제",
                isEnabled: true,
                tint: AppColor.category(.red),
                action: onDelete
            )
        }
        .accessibilityHidden(true)
    }

    private func control(
        systemImage: String,
        label: String,
        isEnabled: Bool,
        tint: Color = AppColor.textFaint,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isEnabled ? tint : AppColor.textDim)
                .frame(width: 26, height: 26)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(label)
    }
}

#Preview {
    VStack(spacing: 0) {
        CategoryRow(
            category: ExpenseCategory(
                name: "주거/생활", symbolName: "house.fill", colorToken: .green, isBuiltIn: true
            ),
            canMoveUp: false, canMoveDown: true,
            onEdit: {}, onMoveUp: {}, onMoveDown: {}, onDelete: {}
        )
        CategoryRow(
            category: ExpenseCategory(
                name: "취미", symbolName: "guitars", colorToken: .purple
            ),
            canMoveUp: true, canMoveDown: false,
            onEdit: {}, onMoveUp: {}, onMoveDown: {}, onDelete: {}
        )
    }
    .background(AppColor.surface)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(AppColor.background)
}
