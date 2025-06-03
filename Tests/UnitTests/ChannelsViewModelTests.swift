import XCTest
@testable import IOSAssignment
import FactoryKit

@MainActor
final class ChannelsViewModelTests: XCTestCase {
    var viewModel: ChannelsViewModel!
    var mockAppManager: MockAppManager!
    
    override func setUp() {
        super.setUp()
        mockAppManager = MockAppManager()
        let appManager = mockAppManager!
        Container.shared.appManager.register { appManager }
        viewModel = ChannelsViewModel()
    }
    
    override func tearDown() {
        Container.shared.reset()
        super.tearDown()
    }
    
    func testLoadChannels() {
        // Given
        let channels = [
            Channel(id: "facebook", channel: "Facebook", monthlyFees: []),
            Channel(id: "linkedin", channel: "LinkedIn", monthlyFees: [])
        ]
        mockAppManager.availableChannels = channels
        
        // When
        viewModel.loadChannels()
        
        // Then
        XCTAssertEqual(viewModel.availableChannels.count, 2)
        XCTAssertEqual(viewModel.availableChannels, channels)
    }
    
    func testGetSelectedCampaign() {
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
        mockAppManager.mockSelectedCampaign = campaign
        
        // When
        let result = viewModel.getSelectedCampaign(for: channel)
        
        // Then
        XCTAssertTrue(mockAppManager.getSelectedCampaignCalled)
        XCTAssertEqual(result?.id, campaign.id)
    }
    
    func testHasSelectedCampaign() {
        // Given
        let channel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        mockAppManager.mockHasSelectedCampaign = true
        
        // When
        let result = viewModel.hasSelectedCampaign(for: channel)
        
        // Then
        XCTAssertTrue(mockAppManager.hasSelectedCampaignCalled)
        XCTAssertTrue(result)
    }
    
    func testSelectedCampaigns() {
        // Given
        let campaigns = [
            Campaign(id: "facebook_0", name: "FB Campaign", description: "Test", monthlyFee: 100.0, details: "Details", currency: "EUR"),
            Campaign(id: "linkedin_0", name: "LI Campaign", description: "Test", monthlyFee: 150.0, details: "Details", currency: "USD")
        ]
        mockAppManager.selectedCampaigns = campaigns
        
        // When
        let result = viewModel.selectedCampaigns
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result, campaigns)
    }
    
    func testSelectedCampaignCount() {
        // Given
        let campaigns = [
            Campaign(id: "facebook_0", name: "FB Campaign", description: "Test", monthlyFee: 100.0, details: "Details", currency: "EUR"),
            Campaign(id: "linkedin_0", name: "LI Campaign", description: "Test", monthlyFee: 150.0, details: "Details", currency: "USD")
        ]
        mockAppManager.selectedCampaigns = campaigns
        
        // When
        let result = viewModel.selectedCampaignCount
        
        // Then
        XCTAssertEqual(result, 2)
    }
    
    func testGetPackagesByChannel() {
        // Given
        let channel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        let campaign = Campaign(id: "facebook_0", name: "Test Campaign", description: "Test", monthlyFee: 100.0, details: "Details", currency: "EUR")
        mockAppManager.mockPackagesByChannel = [(channel: channel, campaign: campaign)]
        
        // When
        let result = viewModel.getPackagesByChannel()
        
        // Then
        XCTAssertTrue(mockAppManager.getPackagesByChannelCalled)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.channel.id, channel.id)
        XCTAssertEqual(result.first?.campaign.id, campaign.id)
    }
    
    func testViewModelDelegatesAllCallsToAppManager() {
        // This test verifies that ChannelsViewModel properly delegates all calls to AppManager
        
        // Given
        let channel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        let campaign = Campaign(id: "facebook_0", name: "Test", description: "Test", monthlyFee: 100.0, details: "Details", currency: "EUR")
        
        mockAppManager.mockSelectedCampaign = campaign
        mockAppManager.mockHasSelectedCampaign = true
        mockAppManager.mockPackagesByChannel = [(channel: channel, campaign: campaign)]
        
        // When - Call all ViewModel methods
        _ = viewModel.getSelectedCampaign(for: channel)
        _ = viewModel.hasSelectedCampaign(for: channel)
        _ = viewModel.selectedCampaigns
        _ = viewModel.hasSelectedCampaigns
        _ = viewModel.selectedCampaignCount
        _ = viewModel.canProceedToReview
        _ = viewModel.getPackagesByChannel()
        _ = viewModel.formattedTotalCost
        
        // Then - All calls should be delegated to AppManager
        XCTAssertTrue(mockAppManager.getSelectedCampaignCalled)
        XCTAssertTrue(mockAppManager.hasSelectedCampaignCalled)
        XCTAssertTrue(mockAppManager.getPackagesByChannelCalled)
        
        // ViewModel should not have any state management logic of its own
        // It should only serve as a bridge between the View and AppManager
    }
}
