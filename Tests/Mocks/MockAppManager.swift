import Foundation
@testable import IOSAssignment

class MockAppManager: AppManager {
    // State tracking
    var setSelectedTargetingSpecificsCalled = false
    var setAvailableChannelsCalled = false
    var selectCampaignCalled = false
    var deselectCampaignCalled = false
    var resetSelectionForChannelCalled = false
    var getSelectedCampaignCalled = false
    var hasSelectedCampaignCalled = false
    var sendEmailCalled = false
    var resetCalled = false
    var getChannelCalled = false
    var getPackagesByChannelCalled = false
    var validateSelectionCalled = false
    
    // Captured parameters
    var lastSelectedTargetingSpecifics: Set<TargetingSpecific>?
    var lastAvailableChannelsParams: (specifics: Set<TargetingSpecific>, allChannels: [Channel])?
    var lastSelectedCampaign: Campaign?
    var lastSelectedChannel: Channel?
    var lastDeselectedCampaign: Campaign?
    var lastDeselectedChannel: Channel?
    var lastResetChannel: Channel?
    var lastChannelForCampaign: Campaign?
    var lastRemovedCampaign: Campaign?
    
    // Mock return values
    var mockSelectedCampaign: Campaign?
    var mockHasSelectedCampaign = false
    var mockChannelForCampaign: Channel?
    var mockPackagesByChannel: [(channel: Channel, campaign: Campaign)] = []
    var mockValidation: (isValid: Bool, message: String?) = (true, nil)
    var sendEmailShouldSucceed = true
    
    // Published properties override
    override var selectedTargetingSpecifics: Set<TargetingSpecific> {
        get { super.selectedTargetingSpecifics }
        set { super.selectedTargetingSpecifics = newValue }
    }
    
    override var availableChannels: [Channel] {
        get { super.availableChannels }
        set { super.availableChannels = newValue }
    }
    
    override var selectedCampaigns: [Campaign] {
        get { super.selectedCampaigns }
        set { super.selectedCampaigns = newValue }
    }
    
    override var canProceedToReview: Bool {
        return false
    }
    
    override var canSendEmail: Bool {
        return false
    }
    
    override var formattedTotalCost: String {
        return ""
    }
    
    override var uniqueChannelCount: Int {
        return 0
    }
    
    // Override methods to track calls
    override func setSelectedTargetingSpecifics(_ specifics: Set<TargetingSpecific>) {
        setSelectedTargetingSpecificsCalled = true
        lastSelectedTargetingSpecifics = specifics
        super.setSelectedTargetingSpecifics(specifics)
    }
    
    override func setAvailableChannels(from targetingSpecifics: Set<TargetingSpecific>, allChannels: [Channel]) {
        setAvailableChannelsCalled = true
        lastAvailableChannelsParams = (targetingSpecifics, allChannels)
        super.setAvailableChannels(from: targetingSpecifics, allChannels: allChannels)
    }
    
    override func selectCampaign(_ campaign: Campaign, for channel: Channel) {
        selectCampaignCalled = true
        lastSelectedCampaign = campaign
        lastSelectedChannel = channel
        super.selectCampaign(campaign, for: channel)
    }
    
    override func deselectCampaign(_ campaign: Campaign, for channel: Channel) {
        deselectCampaignCalled = true
        lastDeselectedCampaign = campaign
        lastDeselectedChannel = channel
        super.deselectCampaign(campaign, for: channel)
    }
    
    override func getSelectedCampaign(for channel: Channel) -> Campaign? {
        getSelectedCampaignCalled = true
        return mockSelectedCampaign ?? super.getSelectedCampaign(for: channel)
    }
    
    override func hasSelectedCampaign(for channel: Channel) -> Bool {
        hasSelectedCampaignCalled = true
        return mockHasSelectedCampaign || super.hasSelectedCampaign(for: channel)
    }
    
    override func resetSelectionForChannel(_ channel: Channel) {
        resetSelectionForChannelCalled = true
        lastResetChannel = channel
        super.resetSelectionForChannel(channel)
    }
    
    override func reset() {
        resetCalled = true
        super.reset()
    }
    
    override func getChannel(for campaign: Campaign) -> Channel? {
        getChannelCalled = true
        lastChannelForCampaign = campaign
        return mockChannelForCampaign ?? super.getChannel(for: campaign)
    }
    
    override func getPackagesByChannel() -> [(channel: Channel, campaign: Campaign)] {
        getPackagesByChannelCalled = true
        return mockPackagesByChannel.isEmpty ? super.getPackagesByChannel() : mockPackagesByChannel
    }
    
    override func validateSelection() -> (isValid: Bool, message: String?) {
        validateSelectionCalled = true
        return mockValidation
    }
    
    // Reset method for tests
    func resetMock() {
        setSelectedTargetingSpecificsCalled = false
        setAvailableChannelsCalled = false
        selectCampaignCalled = false
        deselectCampaignCalled = false
        resetSelectionForChannelCalled = false
        getSelectedCampaignCalled = false
        hasSelectedCampaignCalled = false
        sendEmailCalled = false
        resetCalled = false
        getChannelCalled = false
        getPackagesByChannelCalled = false
        validateSelectionCalled = false
        
        lastSelectedTargetingSpecifics = nil
        lastAvailableChannelsParams = nil
        lastSelectedCampaign = nil
        lastSelectedChannel = nil
        lastDeselectedCampaign = nil
        lastDeselectedChannel = nil
        lastResetChannel = nil
        lastChannelForCampaign = nil
        lastRemovedCampaign = nil
        
        mockSelectedCampaign = nil
        mockHasSelectedCampaign = false
        mockChannelForCampaign = nil
        mockPackagesByChannel = []
        mockValidation = (true, nil)
        sendEmailShouldSucceed = true
        
//        canProceedToReview = false
//        canSendEmail = false
//        formattedTotalCost = ""
//        uniqueChannelCount = 0
    }
}
