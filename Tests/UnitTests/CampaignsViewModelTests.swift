import XCTest
@testable import IOSAssignment
import FactoryKit

@MainActor
final class CampaignsViewModelTests: XCTestCase {
    var viewModel: CampaignsViewModel!
    var mockNetworkService: MockNetworkService!
    var mockAppManager: MockAppManager!
    
    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        mockAppManager = MockAppManager()
        let service = mockNetworkService!
        let appManager = mockAppManager!
        Container.shared.networkService.register { service }
        Container.shared.appManager.register { appManager }
        viewModel = CampaignsViewModel()
    }
    
    override func tearDown() {
        Container.shared.reset()
        super.tearDown()
    }
    
    func testLoadChannelDetailsSuccess() async {
        // Given
        let monthlyFee = MonthlyFee(
            id: "fee1",
            price: 140.0,
            details: ["3-8 listings", "12 optimizations", "Campaign setup"],
            currency: "EUR"
        )
        let detailedChannel = Channel(
            id: "facebook",
            channel: "Facebook",
            monthlyFees: [monthlyFee]
        )
        mockNetworkService.channelDetailsResponse = detailedChannel
        
        let originalChannel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        
        // When
        await viewModel.loadChannelDetails(for: originalChannel)
        
        // Then
        XCTAssertEqual(viewModel.channel?.monthlyFees.count, 1)
        XCTAssertEqual(viewModel.campaigns.count, 1)
        XCTAssertEqual(viewModel.campaigns.first?.monthlyFee, 140.0)
        XCTAssertEqual(viewModel.campaigns.first?.currency, "EUR")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.selectedCampaign) // No previous selection
    }
    
    func testLoadChannelDetailsWithExistingSelection() async {
        // Given
        let monthlyFee = MonthlyFee(
            id: "fee1",
            price: 140.0,
            details: ["3-8 listings"],
            currency: "EUR"
        )
        let detailedChannel = Channel(
            id: "facebook",
            channel: "Facebook",
            monthlyFees: [monthlyFee]
        )
        let existingCampaign = Campaign(
            id: "facebook_0",
            name: "Facebook Package 1",
            description: "Monthly package for Facebook",
            monthlyFee: 140.0,
            details: "3-8 listings",
            currency: "EUR"
        )
        
        mockNetworkService.channelDetailsResponse = detailedChannel
        mockAppManager.mockSelectedCampaign = existingCampaign
        
        let originalChannel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        
        // When
        await viewModel.loadChannelDetails(for: originalChannel)
        
        // Then
        XCTAssertEqual(viewModel.selectedCampaign?.id, existingCampaign.id)
        XCTAssertTrue(viewModel.hasSelectedCampaign)
        XCTAssertEqual(viewModel.selectedCampaignName, existingCampaign.name)
        XCTAssertEqual(viewModel.selectedCampaignPrice, existingCampaign.formattedPrice)
    }
    
    func testSelectCampaign() {
        // Given
        let channel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        let campaign = Campaign(
            id: "facebook_0",
            name: "Test Campaign",
            description: "Test",
            monthlyFee: 100.0,
            details: "Details",
            currency: "EUR"
        )
        viewModel.channel = channel
        
        // When
        viewModel.selectCampaign(campaign)
        
        // Then
        XCTAssertEqual(viewModel.selectedCampaign?.id, campaign.id)
        XCTAssertTrue(viewModel.hasSelectedCampaign)
        XCTAssertTrue(viewModel.isCampaignSelected(campaign))
        XCTAssertEqual(viewModel.selectedCampaignName, campaign.name)
        XCTAssertEqual(viewModel.selectedCampaignPrice, campaign.formattedPrice)
        
        // Verify AppManager was updated
        XCTAssertTrue(mockAppManager.selectCampaignCalled)
        XCTAssertEqual(mockAppManager.lastSelectedCampaign?.id, campaign.id)
        XCTAssertEqual(mockAppManager.lastSelectedChannel?.id, channel.id)
    }
    
    func testDeselectCampaign() {
        // Given
        let channel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        let campaign = Campaign(
            id: "facebook_0",
            name: "Test Campaign",
            description: "Test",
            monthlyFee: 100.0,
            details: "Details",
            currency: "EUR"
        )
        viewModel.channel = channel
        viewModel.selectedCampaign = campaign
        
        // When
        viewModel.deselectCampaign()
        
        // Then
        XCTAssertNil(viewModel.selectedCampaign)
        XCTAssertFalse(viewModel.hasSelectedCampaign)
        XCTAssertFalse(viewModel.isCampaignSelected(campaign))
        XCTAssertNil(viewModel.selectedCampaignName)
        XCTAssertNil(viewModel.selectedCampaignPrice)
        
        // Verify AppManager was updated
        XCTAssertTrue(mockAppManager.deselectCampaignCalled)
        XCTAssertEqual(mockAppManager.lastDeselectedCampaign?.id, campaign.id)
        XCTAssertEqual(mockAppManager.lastDeselectedChannel?.id, channel.id)
    }
    
    func testIsCampaignSelected() {
        // Given
        let campaign1 = Campaign(
            id: "facebook_0",
            name: "Campaign 1",
            description: "Test",
            monthlyFee: 100.0,
            details: "Details",
            currency: "EUR"
        )
        let campaign2 = Campaign(
            id: "facebook_1",
            name: "Campaign 2",
            description: "Test",
            monthlyFee: 200.0,
            details: "Details",
            currency: "EUR"
        )
        
        // When - No selection
        XCTAssertFalse(viewModel.isCampaignSelected(campaign1))
        XCTAssertFalse(viewModel.isCampaignSelected(campaign2))
        
        // When - Select campaign1
        viewModel.selectedCampaign = campaign1
        
        // Then
        XCTAssertTrue(viewModel.isCampaignSelected(campaign1))
        XCTAssertFalse(viewModel.isCampaignSelected(campaign2))
    }
    
    func testResetSelectionForChannel() {
        // Given
        let channel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        let campaign = Campaign(
            id: "facebook_0",
            name: "Test Campaign",
            description: "Test",
            monthlyFee: 100.0,
            details: "Details",
            currency: "EUR"
        )
        viewModel.channel = channel
        viewModel.selectedCampaign = campaign
        
        // When
        viewModel.resetSelectionForChannel()
        
        // Then
        XCTAssertNil(viewModel.selectedCampaign)
        XCTAssertFalse(viewModel.hasSelectedCampaign)
        XCTAssertNil(viewModel.selectedCampaignName)
        XCTAssertNil(viewModel.selectedCampaignPrice)
        
        // Verify AppManager was updated
        XCTAssertTrue(mockAppManager.resetSelectionForChannelCalled)
        XCTAssertEqual(mockAppManager.lastResetChannel?.id, channel.id)
    }
    
    func testLoadChannelDetailsFailure() async {
        // Given
        mockNetworkService.shouldFail = true
        let channel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        
        // When
        await viewModel.loadChannelDetails(for: channel)
        
        // Then
        XCTAssertEqual(viewModel.channel?.id, channel.id)
        XCTAssertTrue(viewModel.campaigns.isEmpty)
        XCTAssertNil(viewModel.selectedCampaign)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testSingleSelectionBehavior() {
        // Given
        let channel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        let campaign1 = Campaign(
            id: "facebook_0",
            name: "Campaign 1",
            description: "Test",
            monthlyFee: 100.0,
            details: "Details",
            currency: "EUR"
        )
        let campaign2 = Campaign(
            id: "facebook_1",
            name: "Campaign 2",
            description: "Test",
            monthlyFee: 200.0,
            details: "Details",
            currency: "EUR"
        )
        
        viewModel.channel = channel
        
        // When - Select first campaign
        viewModel.selectCampaign(campaign1)
        
        // Then
        XCTAssertEqual(viewModel.selectedCampaign?.id, campaign1.id)
        XCTAssertTrue(viewModel.isCampaignSelected(campaign1))
        XCTAssertFalse(viewModel.isCampaignSelected(campaign2))
        
        // When - Select second campaign (should replace first)
        viewModel.selectCampaign(campaign2)
        
        // Then - Only second campaign should be selected in ViewModel
        XCTAssertEqual(viewModel.selectedCampaign?.id, campaign2.id)
        XCTAssertFalse(viewModel.isCampaignSelected(campaign1))
        XCTAssertTrue(viewModel.isCampaignSelected(campaign2))
        
        // Verify AppManager was called for both selections
        XCTAssertTrue(mockAppManager.selectCampaignCalled)
        XCTAssertEqual(mockAppManager.lastSelectedCampaign?.id, campaign2.id)
    }
    
    func testToggleSelectionBehavior() {
        // Given
        let channel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        let campaign = Campaign(
            id: "facebook_0",
            name: "Test Campaign",
            description: "Test",
            monthlyFee: 100.0,
            details: "Details",
            currency: "EUR"
        )
        viewModel.channel = channel
        
        // When - Select campaign
        viewModel.selectCampaign(campaign)
        
        // Then
        XCTAssertTrue(viewModel.isCampaignSelected(campaign))
        XCTAssertTrue(viewModel.hasSelectedCampaign)
        
        // When - Deselect same campaign
        viewModel.deselectCampaign()
        
        // Then
        XCTAssertFalse(viewModel.isCampaignSelected(campaign))
        XCTAssertFalse(viewModel.hasSelectedCampaign)
        XCTAssertNil(viewModel.selectedCampaign)
    }
    
    func testComputedProperties() {
        // Given
        let campaign = Campaign(
            id: "facebook_0",
            name: "Test Campaign",
            description: "Test",
            monthlyFee: 100.0,
            details: "Details",
            currency: "EUR"
        )
        
        // When - No selection
        XCTAssertFalse(viewModel.hasSelectedCampaign)
        XCTAssertNil(viewModel.selectedCampaignName)
        XCTAssertNil(viewModel.selectedCampaignPrice)
        
        // When - With selection
        viewModel.selectedCampaign = campaign
        
        // Then
        XCTAssertTrue(viewModel.hasSelectedCampaign)
        XCTAssertEqual(viewModel.selectedCampaignName, "Test Campaign")
        XCTAssertEqual(viewModel.selectedCampaignPrice, campaign.formattedPrice)
    }
    
    func testChannelToCampaignsConversion() async {
        // Given
        let monthlyFees = [
            MonthlyFee(
                id: "fee1",
                price: 140.0,
                details: ["3-8 listings", "12 optimizations"],
                currency: "EUR"
            ),
            MonthlyFee(
                id: "fee2",
                price: 280.0,
                details: ["8-15 listings", "24 optimizations", "Premium support"],
                currency: "EUR"
            )
        ]
        
        let detailedChannel = Channel(
            id: "facebook",
            channel: "Facebook",
            monthlyFees: monthlyFees
        )
        mockNetworkService.channelDetailsResponse = detailedChannel
        
        let originalChannel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        
        // When
        await viewModel.loadChannelDetails(for: originalChannel)
        
        // Then
        XCTAssertEqual(viewModel.campaigns.count, 2)
        XCTAssertEqual(viewModel.campaigns[0].name, "Facebook Package 1")
        XCTAssertEqual(viewModel.campaigns[1].name, "Facebook Package 2")
        XCTAssertEqual(viewModel.campaigns[0].monthlyFee, 140.0)
        XCTAssertEqual(viewModel.campaigns[1].monthlyFee, 280.0)
        XCTAssertEqual(viewModel.campaigns[0].currency, "EUR")
        XCTAssertEqual(viewModel.campaigns[1].currency, "EUR")
    }
    
    func testLoadingStateManagement() async {
        // Given
        let channel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        XCTAssertFalse(viewModel.isLoading)
        
        // When - Start loading
        let loadingTask = Task {
            await viewModel.loadChannelDetails(for: channel)
        }
        
        // Give a moment for loading to start
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        await loadingTask.value
        
        // Then - Should not be loading after completion
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testSelectCampaignWithoutChannel() {
        // Given
        let campaign = Campaign(
            id: "facebook_0",
            name: "Test Campaign",
            description: "Test",
            monthlyFee: 100.0,
            details: "Details",
            currency: "EUR"
        )
        // No channel set
        
        // When
        viewModel.selectCampaign(campaign)
        
        // Then - Should not update anything since no channel is set
        XCTAssertNil(viewModel.selectedCampaign)
        XCTAssertFalse(mockAppManager.selectCampaignCalled)
    }
    
    func testDeselectCampaignWithoutChannel() {
        // Given
        let campaign = Campaign(
            id: "facebook_0",
            name: "Test Campaign",
            description: "Test",
            monthlyFee: 100.0,
            details: "Details",
            currency: "EUR"
        )
        viewModel.selectedCampaign = campaign
        // No channel set
        
        // When
        viewModel.deselectCampaign()
        
        // Then - Should not call AppManager since no channel is set
        XCTAssertEqual(viewModel.selectedCampaign?.id, campaign.id) // Should remain unchanged
        XCTAssertFalse(mockAppManager.deselectCampaignCalled)
    }
    
    func testLegacyMethodsBackwardsCompatibility() {
        // Given
        let channel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        let campaign = Campaign(
            id: "facebook_0",
            name: "Test Campaign",
            description: "Test",
            monthlyFee: 100.0,
            details: "Details",
            currency: "EUR"
        )
        viewModel.channel = channel
        
        // When
        viewModel.selectCampaign(campaign)
        
        // Then - Should still work and update local state
        XCTAssertEqual(viewModel.selectedCampaign?.id, campaign.id)
        XCTAssertTrue(mockAppManager.selectCampaignCalled)
        
        // When
        viewModel.deselectCampaign()
        
        // Then
        XCTAssertNil(viewModel.selectedCampaign)
        XCTAssertTrue(mockAppManager.deselectCampaignCalled)
    }
    
    func testViewModelSyncWithAppManagerOnLoad() async {
        // This test verifies that the ViewModel syncs with AppManager state when loading
        
        // Given
        let channel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        let existingCampaign = Campaign(
            id: "facebook_0",
            name: "Existing Campaign",
            description: "Test",
            monthlyFee: 100.0,
            details: "Details",
            currency: "EUR"
        )
        
        // AppManager already has a selection for this channel
        mockAppManager.mockSelectedCampaign = existingCampaign
        
        // When
        await viewModel.loadChannelDetails(for: channel)
        
        // Then - ViewModel should sync with AppManager state
        XCTAssertEqual(viewModel.selectedCampaign?.id, existingCampaign.id)
        XCTAssertTrue(viewModel.hasSelectedCampaign)
        XCTAssertTrue(mockAppManager.getSelectedCampaignCalled)
    }
    
    func testReactiveUIUpdatesWithPublishedProperties() {
        // This test verifies that @Published properties trigger UI updates
        
        // Given
        let campaign = Campaign(
            id: "facebook_0",
            name: "Test Campaign",
            description: "Test",
            monthlyFee: 100.0,
            details: "Details",
            currency: "EUR"
        )
        
        // Capture initial state
        let initialHasSelection = viewModel.hasSelectedCampaign
        let initialName = viewModel.selectedCampaignName
        
        // When - Update @Published property
        viewModel.selectedCampaign = campaign
        
        // Then - Computed properties should reflect the change
        XCTAssertNotEqual(viewModel.hasSelectedCampaign, initialHasSelection)
        XCTAssertNotEqual(viewModel.selectedCampaignName, initialName)
        XCTAssertTrue(viewModel.hasSelectedCampaign)
        XCTAssertEqual(viewModel.selectedCampaignName, "Test Campaign")
    }
}
