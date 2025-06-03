import SwiftUI
import FactoryKit

@MainActor
class AppCoordinator: ObservableObject {
    @Published var navigationPath = NavigationPath()
    
    private let viewFactory: ViewFactoryProtocol
    
    init(viewFactory: ViewFactoryProtocol = Container.shared.viewFactory()) {
        self.viewFactory = viewFactory
    }
    
    // MARK: - Navigation Methods
    
    func moveToChannels() {
        print("📍 Moving to channels")
        navigationPath.append(AppStep.channels)
    }
    
    func moveToCampaigns(for channel: Channel) {
        navigationPath.append(AppStep.campaigns(channel))
    }
    
    func moveToReview() {
        navigationPath.append(AppStep.review)
    }
    
    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    func reset() {
        navigationPath.removeLast(navigationPath.count)
        print("🔄 Reset navigation")
    }
    
    // MARK: - View Factory Methods
    
    func makeView(for step: AppStep) -> AnyView {
        switch step {
        case .channels:
            return AnyView(viewFactory.makeChannelsView())
        case .campaigns(let channel):
            return AnyView(viewFactory.makeCampaignsView(for: channel))
        case .review:
            return AnyView(viewFactory.makeReviewView())
        }
    }
    
    func makeRootView() -> TargetingView {
        return viewFactory.makeTargetingView()
    }
}

enum AppStep: Hashable {
    case channels
    case campaigns(Channel)
    case review
}
