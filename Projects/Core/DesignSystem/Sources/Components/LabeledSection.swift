import SwiftUI

/// 작은 제목 + 내용. 입력 화면에서 묶음을 구분하는 데 쓴다.
public struct LabeledSection<Content: View>: View {
    private let title: String
    private let content: () -> Content

    public init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppFont.overline)
                .tracking(1.2)
                .foregroundStyle(AppColor.textFaint)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    LabeledSection("카테고리") {
        RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
            .fill(AppColor.surface)
            .frame(height: 80)
    }
    .padding()
    .background(AppColor.background)
}
