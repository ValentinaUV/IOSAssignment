import SwiftUI

struct ContentView: View {
    @StateObject private var coordinator = AppCoordinator()
    
    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            coordinator.makeRootView()
                .navigationDestination(for: AppStep.self) { step in
                    coordinator.makeView(for: step)
                }
        }
        .environmentObject(coordinator)
    }
}

#Preview {
    ContentView()
}