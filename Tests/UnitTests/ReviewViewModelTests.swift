import XCTest
@testable import IOSAssignment
import FactoryKit

@MainActor
final class ReviewViewModelTests: XCTestCase {
    var viewModel: ReviewViewModel!
    var mockAppManager: MockAppManager!
    let campaigns = [
        Campaign(id: "facebook_0", name: "FB Campaign", description: "Test", monthlyFee: 100.0, details: "Details", currency: "EUR"),
        Campaign(id: "linkedin_0", name: "LI Campaign", description: "Test", monthlyFee: 150.0, details: "Details", currency: "USD")
    ]
    
    override func setUp() {
        super.setUp()
        mockAppManager = MockAppManager()
        mockAppManager.selectedCampaigns = campaigns
        let appManager = mockAppManager!
        Container.shared.appManager.register { appManager }
        viewModel = ReviewViewModel()
    }
    
    override func tearDown() {
        Container.shared.reset()
        super.tearDown()
    }
    
    // MARK: - Campaign Access Tests
    
    func testSelectedCampaigns() {
        
        // When
        let result = viewModel.selectedCampaigns
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result, campaigns)
    }
    
    func testSelectedCampaignCount() {
        
        // When
        let result = viewModel.selectedCampaignCount
        
        // Then
        XCTAssertEqual(result, 2)
    }
    
    // MARK: - Campaign Management Tests
    
    func testRemoveCampaignWithChannel() {
        // Given
        let channel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        let campaign = Campaign(id: "facebook_0", name: "Test Campaign", description: "Test", monthlyFee: 100.0, details: "Details", currency: "EUR")
        mockAppManager.mockChannelForCampaign = channel
        
        // When
        viewModel.removeCampaign(campaign)
        
        // Then
        XCTAssertTrue(mockAppManager.getChannelCalled)
        XCTAssertTrue(mockAppManager.deselectCampaignCalled)
        XCTAssertEqual(mockAppManager.lastDeselectedCampaign?.id, campaign.id)
        XCTAssertEqual(mockAppManager.lastDeselectedChannel?.id, channel.id)
    }
    
    func testGetChannelForCampaign() {
        // Given
        let channel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        let campaign = Campaign(id: "facebook_0", name: "Test Campaign", description: "Test", monthlyFee: 100.0, details: "Details", currency: "EUR")
        mockAppManager.mockChannelForCampaign = channel
        
        // When
        let result = viewModel.getChannel(for: campaign)
        
        // Then
        XCTAssertTrue(mockAppManager.getChannelCalled)
        XCTAssertEqual(result?.id, channel.id)
        XCTAssertEqual(mockAppManager.lastChannelForCampaign?.id, campaign.id)
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
    
    // MARK: - Validation Tests
    
    func testValidateSelectionSuccess() {
        // Given
        mockAppManager.mockValidation = (isValid: true, message: nil)
        
        // When
        let result = viewModel.validateSelection()
        
        // Then
        XCTAssertTrue(mockAppManager.validateSelectionCalled)
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.message)
    }
    
    func testValidateSelectionFailure() {
        // Given
        mockAppManager.mockValidation = (isValid: false, message: "No campaigns selected")
        
        // When
        let result = viewModel.validateSelection()
        
        // Then
        XCTAssertTrue(mockAppManager.validateSelectionCalled)
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.message, "No campaigns selected")
    }
    
    // MARK: - Integration Tests
    
    func testViewModelDelegatesAllOperationsToAppManager() {
        // This test verifies that ReviewViewModel properly delegates all operations to AppManager
        
        // Given
        let channel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        let campaign = Campaign(id: "facebook_0", name: "Test", description: "Test", monthlyFee: 100.0, details: "Details", currency: "EUR")
        
        mockAppManager.selectedCampaigns = [campaign]
        mockAppManager.mockChannelForCampaign = channel
        mockAppManager.mockPackagesByChannel = [(channel: channel, campaign: campaign)]
        mockAppManager.mockValidation = (isValid: true, message: nil)
        
        // When - Call all ViewModel methods
        _ = viewModel.selectedCampaigns
        _ = viewModel.hasSelectedCampaigns
        _ = viewModel.selectedCampaignCount
        _ = viewModel.uniqueChannelCount
        _ = viewModel.formattedTotalCost
        viewModel.removeCampaign(campaign)
        _ = viewModel.getChannel(for: campaign)
        _ = viewModel.getPackagesByChannel()
        _ = viewModel.validateSelection()
        
        // Then - All operations should be delegated to AppManager
        XCTAssertTrue(mockAppManager.getChannelCalled)
        XCTAssertTrue(mockAppManager.deselectCampaignCalled)
        XCTAssertTrue(mockAppManager.getPackagesByChannelCalled)
        XCTAssertTrue(mockAppManager.validateSelectionCalled)
        
        // ViewModel should not have any business logic of its own
        // It should only manage loading state and delegate everything else to AppManager
    }
}
