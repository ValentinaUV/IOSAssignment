import Foundation
import FactoryKit

@MainActor
class ChannelsViewModel: ObservableObject {
    @Published var availableChannels: [Channel] = []
    
    private let appManager: AppManager
    
    init(appManager: AppManager = Container.shared.appManager()) {
        self.appManager = appManager
    }
    
    func loadChannels() {
        availableChannels = appManager.availableChannels
    }
    
    // MARK: - Campaign Management
    
    func getSelectedCampaign(for channel: Channel) -> Campaign? {
        return appManager.getSelectedCampaign(for: channel)
    }
    
    func hasSelectedCampaign(for channel: Channel) -> Bool {
        return appManager.hasSelectedCampaign(for: channel)
    }
    
    var selectedCampaigns: [Campaign] {
        return appManager.selectedCampaigns
    }
    
    var hasSelectedCampaigns: Bool {
        return appManager.hasSelectedCampaigns
    }
    
    var selectedCampaignCount: Int {
        return appManager.selectedCampaignCount
    }
    
    var canProceedToReview: Bool {
        return appManager.canProceedToReview
    }
    
    // MARK: - Channel-Campaign Association
    
    func getPackagesByChannel() -> [(channel: Channel, campaign: Campaign)] {
        return appManager.getPackagesByChannel()
    }
    
    var formattedTotalCost: String {
        return appManager.formattedTotalCost
    }
}