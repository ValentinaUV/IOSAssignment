import Foundation
import FactoryKit

@MainActor
class CampaignsViewModel: ObservableObject {
    @Published var channel: Channel?
    @Published var campaigns: [Campaign] = []
    @Published var selectedCampaign: Campaign?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkService: NetworkServiceProtocol
    private let appManager: AppManager
    
    init(
        networkService: NetworkServiceProtocol = Container.shared.networkService(),
        appManager: AppManager = Container.shared.appManager()
    ) {
        self.networkService = networkService
        self.appManager = appManager
    }
    
    func loadChannelDetails(for channel: Channel) async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔄 Loading channel details for: \(channel.name)")
            let detailedChannel = try await networkService.fetchChannelDetails(for: channel)
            
            self.channel = detailedChannel
            self.campaigns = detailedChannel.toCampaigns()
            
            // Load existing selection from AppManager
            self.selectedCampaign = appManager.getSelectedCampaign(for: channel)
            
            print("✅ Successfully loaded \(campaigns.count) campaigns for \(channel.name)")
            
        } catch {
            print("❌ Failed to load channel details for \(channel.name): \(error)")
            errorMessage = "Failed to load channel details: \(error.localizedDescription)"
            
            // Set empty channel and campaigns on error
            self.channel = channel
            self.campaigns = []
            self.selectedCampaign = nil
        }
        
        isLoading = false
    }
    
    // MARK: - Campaign Selection
    
    func selectCampaign(_ campaign: Campaign) {
        guard let channel = channel else { return }
        
        // Update local state immediately for UI responsiveness
        selectedCampaign = campaign
        
        // Update AppManager state
        appManager.selectCampaign(campaign, for: channel)
        
        print("✅ Selected campaign: \(campaign.name) for channel: \(channel.name)")
    }
    
    func deselectCampaign() {
        guard let channel = channel, let campaign = selectedCampaign else { return }
        
        // Update local state immediately
        selectedCampaign = nil
        
        // Update AppManager state
        appManager.deselectCampaign(campaign, for: channel)
        
        print("❌ Deselected campaign for channel: \(channel.name)")
    }
    
    func isCampaignSelected(_ campaign: Campaign) -> Bool {
        return selectedCampaign?.id == campaign.id
    }
    
    func resetSelectionForChannel() {
        guard let channel = channel else { return }
        
        // Update local state
        selectedCampaign = nil
        
        // Update AppManager state
        appManager.resetSelectionForChannel(channel)
        
        print("🔄 Reset selection for channel: \(channel.name)")
    }
    
    // MARK: - Computed Properties
    
    var hasSelectedCampaign: Bool {
        return selectedCampaign != nil
    }
    
    var selectedCampaignName: String? {
        return selectedCampaign?.name
    }
    
    var selectedCampaignPrice: String? {
        return selectedCampaign?.formattedPrice
    }
}