import Foundation
import FactoryKit

@MainActor
class AppManager: ObservableObject {
    @Published var selectedTargetingSpecifics: Set<TargetingSpecific> = []
    @Published var availableChannels: [Channel] = []
    @Published var selectedCampaigns: [Campaign] = []
    
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol = Container.shared.networkService()) {
        self.networkService = networkService
    }
    
    // MARK: - Targeting Management
    
    func setSelectedTargetingSpecifics(_ specifics: Set<TargetingSpecific>) {
        selectedTargetingSpecifics = specifics
        print("📝 Updated selected targeting specifics: \(specifics.map { $0.target })")
    }
    
    func setAvailableChannels(from targetingSpecifics: Set<TargetingSpecific>, allChannels: [Channel]) {
        // Filter channels based on selected targeting specifics
        // Get all available channels from the selected targeting specifics
        var filteredChannels: [Channel] = []
        var channelIds = Set<String>()
        
        for targeting in targetingSpecifics {
            for availableChannel in targeting.availableChannels {
                let channelName = availableChannel.channel
                let channelId = channelName.lowercased().replacingOccurrences(of: " ", with: "_")
                
                if !channelIds.contains(channelId) {
                    channelIds.insert(channelId)
                    
                    // Find the corresponding full channel or create one
                    if let fullChannel = allChannels.first(where: { $0.id == channelId || $0.name.lowercased() == channelName.lowercased() }) {
                        filteredChannels.append(fullChannel)
                    } else {
                        // Create a basic channel if not found
                        let newChannel = Channel(
                            id: channelId,
                            channel: channelName,
                            monthlyFees: []
                        )
                        filteredChannels.append(newChannel)
                    }
                }
            }
        }
        
        availableChannels = filteredChannels
        
        print("📍 Updated available channels: \(filteredChannels.map { $0.name })")
        print("📍 Channels derived from \(targetingSpecifics.count) targeting specifics")
    }
    
    // MARK: - Campaign Management (Single Selection Per Channel)
    
    func selectCampaign(_ campaign: Campaign, for channel: Channel) {
        // Remove any existing campaign from the same channel
        selectedCampaigns.removeAll { existingCampaign in
            // Check if the existing campaign belongs to the same channel
            // We can determine this by checking if the campaign ID starts with the channel ID
            existingCampaign.id.hasPrefix(channel.id)
        }
        
        // Add the new campaign
        selectedCampaigns.append(campaign)
        
        print("✅ Selected campaign: \(campaign.name) (\(campaign.formattedPrice)) for channel: \(channel.name)")
        print("📊 Total selected campaigns: \(selectedCampaigns.count)")
        print("📊 Campaigns per channel: \(getSelectedCampaignsPerChannel())")
    }
    
    func deselectCampaign(_ campaign: Campaign, for channel: Channel) {
        selectedCampaigns.removeAll { $0.id == campaign.id }
        print("❌ Deselected campaign: \(campaign.name) for channel: \(channel.name)")
        print("📊 Total selected campaigns: \(selectedCampaigns.count)")
    }
    
    func getSelectedCampaign(for channel: Channel) -> Campaign? {
        return selectedCampaigns.first { campaign in
            campaign.id.hasPrefix(channel.id)
        }
    }
    
    func hasSelectedCampaign(for channel: Channel) -> Bool {
        return getSelectedCampaign(for: channel) != nil
    }
    
    func resetSelectionForChannel(_ channel: Channel) {
        selectedCampaigns.removeAll { campaign in
            campaign.id.hasPrefix(channel.id)
        }
        print("🔄 Reset selection for channel: \(channel.name)")
        print("📊 Total selected campaigns: \(selectedCampaigns.count)")
    }
    
    // MARK: - Helper Methods
    
    private func getSelectedCampaignsPerChannel() -> [String: String] {
        var result: [String: String] = [:]
        
        for channel in availableChannels {
            if let selectedCampaign = getSelectedCampaign(for: channel) {
                result[channel.name] = selectedCampaign.name
            }
        }
        
        return result
    }
    
    // MARK: - State Management
    
    func reset() {
        selectedTargetingSpecifics.removeAll()
        availableChannels.removeAll()
        selectedCampaigns.removeAll()
        print("🔄 Reset all app state")
    }
    
    // MARK: - Computed Properties for UI
    
    var hasSelectedCampaigns: Bool {
        return !selectedCampaigns.isEmpty
    }
    
    var selectedCampaignCount: Int {
        return selectedCampaigns.count
    }
    
    var uniqueChannelCount: Int {
        let channelIds = Set(selectedCampaigns.compactMap { campaign in
            availableChannels.first { channel in
                campaign.id.hasPrefix(channel.id)
            }?.id
        })
        return channelIds.count
    }
    
    var totalMonthlyCost: [String: Double] {
        // Group campaigns by currency and calculate totals
        return Dictionary(grouping: selectedCampaigns, by: { $0.currency })
            .mapValues { campaigns in
                campaigns.reduce(0) { $0 + $1.monthlyFee }
            }
    }
    
    var formattedTotalCost: String {
        let formattedTotals = totalMonthlyCost.map { currency, total in
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = currency
            return formatter.string(from: NSNumber(value: total)) ?? "\(currency) \(total)"
        }
        
        return formattedTotals.joined(separator: " + ")
    }
    
    // MARK: - Channel-Campaign Association Helpers
    
    func getChannel(for campaign: Campaign) -> Channel? {
        return availableChannels.first { channel in
            campaign.id.hasPrefix(channel.id)
        }
    }
    
    func getPackagesByChannel() -> [(channel: Channel, campaign: Campaign)] {
        return selectedCampaigns.compactMap { campaign in
            if let channel = getChannel(for: campaign) {
                return (channel: channel, campaign: campaign)
            }
            return nil
        }.sorted { $0.channel.name < $1.channel.name }
    }
    
    // MARK: - Validation
    
    var canProceedToReview: Bool {
        return hasSelectedCampaigns
    }
    
    var canSendEmail: Bool {
        return hasSelectedCampaigns
    }
    
    func validateSelection() -> (isValid: Bool, message: String?) {
        guard hasSelectedCampaigns else {
            return (false, "No campaigns selected")
        }
        
        guard uniqueChannelCount > 0 else {
            return (false, "No valid channel associations")
        }
        
        return (true, nil)
    }
}
