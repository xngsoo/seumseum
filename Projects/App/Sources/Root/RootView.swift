import SwiftUI
import DesignSystem
import Domain
import Persistence

struct RootView: View {
    enum Phase {
        case loading
        case ready(PersistenceStack)
        case failed(String)
    }

    @State private var phase: Phase = .loading
    @State private var navigation = AppNavigation()
    @State private var appearance = AppearanceStore()

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColor.background)
            // 색 토큰은 정적으로 읽혀서, 테마가 바뀌면 화면을 통째로 다시 그려야 한다.
            .id(appearance.theme)
            // 끄면 시스템 설정과 무관하게 언제나 밝은 화면이다.
            .preferredColorScheme(appearance.isDarkMode ? .dark : .light)
            // 글자 크기는 고정한다. 격자·칩·키패드처럼 폭과 높이가 정해진 배치가 많아
            // 시스템 설정을 따라가면 줄이 겹치거나 잘린다.
            .dynamicTypeSize(.large)
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .loading:
            ProgressView()
                .task { await bootstrap() }
        case let .ready(stack):
            MainTabView(stack: stack)
                .environment(navigation)
                .environment(appearance)
        case let .failed(message):
            BootstrapFailureView(message: message) {
                phase = .loading
            }
        }
    }

    private func bootstrap() async {
        do {
            let stack = try await PersistenceStack()
            #if DEBUG
            try await SampleData.seedIfRequested(into: stack)
            #endif
            // 첫 화면을 그리기 전에 색을 맞춰 둔다. 뒤늦게 바꾸면 한 번 번쩍인다.
            if let settings = try? await stack.settings.settings() {
                appearance.apply(theme: settings.theme, isDarkMode: settings.isDarkMode)
            }
            phase = .ready(stack)
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}

#Preview {
    RootView()
}
