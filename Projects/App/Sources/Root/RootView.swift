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

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColor.background)
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
            phase = .ready(stack)
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}

#Preview {
    RootView()
}
