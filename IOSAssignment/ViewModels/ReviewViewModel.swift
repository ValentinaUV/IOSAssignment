import Foundation
import FactoryKit

@MainActor
class ReviewViewModel: ObservableObject {
    @Published var selectedCampaigns: [Campaign] = []
    
    private let appManager: AppManager
    
    init(appManager: AppManager = Container.shared.appManager()) {
        self.appManager = appManager
        self.selectedCampaigns = appManager.selectedCampaigns
    }
    
    var hasSelectedCampaigns: Bool {
        return appManager.hasSelectedCampaigns
    }
    
    var selectedCampaignCount: Int {
        return appManager.selectedCampaignCount
    }
    
    var uniqueChannelCount: Int {
        return appManager.uniqueChannelCount
    }
    
    var formattedTotalCost: String {
        return appManager.formattedTotalCost
    }
    
    // MARK: - Campaign Management
    
    func removeCampaign(_ campaign: Campaign) {
        if let channel = appManager.getChannel(for: campaign) {
            appManager.deselectCampaign(campaign, for: channel)
            selectedCampaigns = appManager.selectedCampaigns
        }
    }
    
    func getChannel(for campaign: Campaign) -> Channel? {
        return appManager.getChannel(for: campaign)
    }
    
    func getPackagesByChannel() -> [(channel: Channel, campaign: Campaign)] {
        return appManager.getPackagesByChannel()
    }
    
    // MARK: - Validation
    
    func validateSelection() -> (isValid: Bool, message: String?) {
        return appManager.validateSelection()
    }
}
