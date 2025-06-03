import XCTest
@testable import IOSAssignment
import FactoryKit

@MainActor
final class AppManagerTests: XCTestCase {
    var appManager: AppManager!
    var mockNetworkService: MockNetworkService!
    
    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        let service = mockNetworkService!
        Container.shared.networkService.register { service }
        appManager = AppManager()
    }
    
    override func tearDown() {
        Container.shared.reset()
        super.tearDown()
    }
    
    // MARK: - Targeting Management Tests
    
    func testSetSelectedTargetingSpecifics() {
        // Given
        let availableChannel = AvailableChannel(
            id: "facebook_test",
            channel: "Facebook",
            channelId: "test123"
        )
        let specific = TargetingSpecific(
            id: "location",
            target: "Location",
            availableChannels: [availableChannel]
        )
        let specifics: Set<TargetingSpecific> = [specific]
        
        // When
        appManager.setSelectedTargetingSpecifics(specifics)
        
        // Then
        XCTAssertEqual(appManager.selectedTargetingSpecifics, specifics)
        XCTAssertEqual(appManager.selectedTargetingSpecifics.count, 1)
        XCTAssertEqual(appManager.selectedTargetingSpecifics.first?.target, "Location")
    }
    
    func testSetAvailableChannels() {
        // Given
        let availableChannels = [
            AvailableChannel(id: "facebook_location", channel: "Facebook", channelId: "fb123"),
            AvailableChannel(id: "linkedin_location", channel: "LinkedIn", channelId: "li123")
        ]
        
        let locationTargeting = TargetingSpecific(
            id: "location",
            target: "Location",
            availableChannels: availableChannels
        )
        
        let allChannels = [
            Channel(id: "facebook", channel: "Facebook", monthlyFees: []),
            Channel(id: "linkedin", channel: "LinkedIn", monthlyFees: [])
        ]
        
        let selectedSpecifics: Set<TargetingSpecific> = [locationTargeting]
        
        // When
        appManager.setAvailableChannels(from: selectedSpecifics, allChannels: allChannels)
        
        // Then
        XCTAssertEqual(appManager.availableChannels.count, 2)
        XCTAssertTrue(appManager.availableChannels.contains { $0.name == "Facebook" })
        XCTAssertTrue(appManager.availableChannels.contains { $0.name == "LinkedIn" })
    }
    
    // MARK: - Single Campaign Selection Tests
    
    func testSelectSingleCampaignPerChannel() {
        // Given
        let channel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        let campaign1 = Campaign(
            id: "facebook_0",
            name: "Facebook Basic",
            description: "Basic package",
            monthlyFee: 100.0,
            details: "Basic features",
            currency: "EUR"
        )
        let campaign2 = Campaign(
            id: "facebook_1",
            name: "Facebook Premium",
            description: "Premium package",
            monthlyFee: 200.0,
            details: "Premium features",
            currency: "EUR"
        )
        
        appManager.availableChannels = [channel]
        
        // When - Select first campaign
        appManager.selectCampaign(campaign1, for: channel)
        
        // Then
        XCTAssertEqual(appManager.selectedCampaigns.count, 1)
        XCTAssertTrue(appManager.selectedCampaigns.contains(campaign1))
        XCTAssertEqual(appManager.getSelectedCampaign(for: channel)?.id, campaign1.id)
        XCTAssertTrue(appManager.hasSelectedCampaign(for: channel))
        
        // When - Select second campaign (should replace first)
        appManager.selectCampaign(campaign2, for: channel)
        
        // Then - Only second campaign should be selected
        XCTAssertEqual(appManager.selectedCampaigns.count, 1)
        XCTAssertFalse(appManager.selectedCampaigns.contains(campaign1))
        XCTAssertTrue(appManager.selectedCampaigns.contains(campaign2))
        XCTAssertEqual(appManager.getSelectedCampaign(for: channel)?.id, campaign2.id)
    }
    
    func testSelectCampaignsFromMultipleChannels() {
        // Given
        let facebookChannel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        let linkedinChannel = Channel(id: "linkedin", channel: "LinkedIn", monthlyFees: [])
        
        let facebookCampaign = Campaign(
            id: "facebook_0",
            name: "Facebook Basic",
            description: "Basic package",
            monthlyFee: 100.0,
            details: "Basic features",
            currency: "EUR"
        )
        let linkedinCampaign = Campaign(
            id: "linkedin_0",
            name: "LinkedIn Basic",
            description: "Basic package",
            monthlyFee: 150.0,
            details: "Basic features",
            currency: "USD"
        )
        
        appManager.availableChannels = [facebookChannel, linkedinChannel]
        
        // When - Select campaigns from different channels
        appManager.selectCampaign(facebookCampaign, for: facebookChannel)
        appManager.selectCampaign(linkedinCampaign, for: linkedinChannel)
        
        // Then - Both campaigns should be selected
        XCTAssertEqual(appManager.selectedCampaigns.count, 2)
        XCTAssertTrue(appManager.selectedCampaigns.contains(facebookCampaign))
        XCTAssertTrue(appManager.selectedCampaigns.contains(linkedinCampaign))
        XCTAssertEqual(appManager.getSelectedCampaign(for: facebookChannel)?.id, facebookCampaign.id)
        XCTAssertEqual(appManager.getSelectedCampaign(for: linkedinChannel)?.id, linkedinCampaign.id)
    }
    
    func testDeselectCampaign() {
        // Given
        let channel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        let campaign = Campaign(
            id: "facebook_0",
            name: "Facebook Basic",
            description: "Basic package",
            monthlyFee: 100.0,
            details: "Basic features",
            currency: "EUR"
        )
        
        appManager.availableChannels = [channel]
        appManager.selectCampaign(campaign, for: channel)
        
        // When
        appManager.deselectCampaign(campaign, for: channel)
        
        // Then
        XCTAssertEqual(appManager.selectedCampaigns.count, 0)
        XCTAssertFalse(appManager.selectedCampaigns.contains(campaign))
        XCTAssertNil(appManager.getSelectedCampaign(for: channel))
        XCTAssertFalse(appManager.hasSelectedCampaign(for: channel))
    }
    
    func testResetSelectionForChannel() {
        // Given
        let facebookChannel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        let linkedinChannel = Channel(id: "linkedin", channel: "LinkedIn", monthlyFees: [])
        
        let facebookCampaign = Campaign(
            id: "facebook_0",
            name: "Facebook Basic",
            description: "Basic package",
            monthlyFee: 100.0,
            details: "Basic features",
            currency: "EUR"
        )
        let linkedinCampaign = Campaign(
            id: "linkedin_0",
            name: "LinkedIn Basic",
            description: "Basic package",
            monthlyFee: 150.0,
            details: "Basic features",
            currency: "USD"
        )
        
        appManager.availableChannels = [facebookChannel, linkedinChannel]
        appManager.selectCampaign(facebookCampaign, for: facebookChannel)
        appManager.selectCampaign(linkedinCampaign, for: linkedinChannel)
        
        // When - Reset selection for Facebook only
        appManager.resetSelectionForChannel(facebookChannel)
        
        // Then - Only LinkedIn campaign should remain
        XCTAssertEqual(appManager.selectedCampaigns.count, 1)
        XCTAssertFalse(appManager.selectedCampaigns.contains(facebookCampaign))
        XCTAssertTrue(appManager.selectedCampaigns.contains(linkedinCampaign))
        XCTAssertNil(appManager.getSelectedCampaign(for: facebookChannel))
        XCTAssertEqual(appManager.getSelectedCampaign(for: linkedinChannel)?.id, linkedinCampaign.id)
    }
    
    // MARK: - State Management Tests
    
    func testReset() {
        // Given
        let availableChannel = AvailableChannel(
            id: "facebook_test",
            channel: "Facebook",
            channelId: "test123"
        )
        let specific = TargetingSpecific(
            id: "location",
            target: "Location",
            availableChannels: [availableChannel]
        )
        let channel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        let campaign = Campaign(
            id: "facebook_0",
            name: "Test",
            description: "Test",
            monthlyFee: 100.0,
            details: "Details",
            currency: "EUR"
        )
        
        appManager.setSelectedTargetingSpecifics([specific])
        appManager.availableChannels.append(channel)
        appManager.selectCampaign(campaign, for: channel)
        
        // When
        appManager.reset()
        
        // Then
        XCTAssertTrue(appManager.selectedTargetingSpecifics.isEmpty)
        XCTAssertTrue(appManager.availableChannels.isEmpty)
        XCTAssertTrue(appManager.selectedCampaigns.isEmpty)
    }
    
    // MARK: - Computed Properties Tests
    
    func testComputedProperties() {
        // Given - No campaigns selected
        XCTAssertFalse(appManager.hasSelectedCampaigns)
        XCTAssertEqual(appManager.selectedCampaignCount, 0)
        XCTAssertEqual(appManager.uniqueChannelCount, 0)
        XCTAssertTrue(appManager.totalMonthlyCost.isEmpty)
        
        // When - Add campaigns
        let facebookChannel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        let linkedinChannel = Channel(id: "linkedin", channel: "LinkedIn", monthlyFees: [])
        
        let facebookCampaign = Campaign(
            id: "facebook_0",
            name: "Facebook Basic",
            description: "Basic package",
            monthlyFee: 100.0,
            details: "Basic features",
            currency: "EUR"
        )
        let linkedinCampaign = Campaign(
            id: "linkedin_0",
            name: "LinkedIn Basic",
            description: "Basic package",
            monthlyFee: 150.0,
            details: "Basic features",
            currency: "USD"
        )
        
        appManager.availableChannels = [facebookChannel, linkedinChannel]
        appManager.selectCampaign(facebookCampaign, for: facebookChannel)
        appManager.selectCampaign(linkedinCampaign, for: linkedinChannel)
        
        // Then
        XCTAssertTrue(appManager.hasSelectedCampaigns)
        XCTAssertEqual(appManager.selectedCampaignCount, 2)
        XCTAssertEqual(appManager.uniqueChannelCount, 2)
        XCTAssertEqual(appManager.totalMonthlyCost["EUR"], 100.0)
        XCTAssertEqual(appManager.totalMonthlyCost["USD"], 150.0)
        XCTAssertTrue(appManager.formattedTotalCost.contains("EUR") || appManager.formattedTotalCost.contains("€"))
        XCTAssertTrue(appManager.formattedTotalCost.contains("USD") || appManager.formattedTotalCost.contains("$"))
    }
    
    func testFormattedTotalCostMultiCurrency() {
        // Given
        let facebookChannel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        let linkedinChannel = Channel(id: "linkedin", channel: "LinkedIn", monthlyFees: [])
        
        let eurCampaign = Campaign(
            id: "facebook_0",
            name: "EUR Campaign",
            description: "Test",
            monthlyFee: 100.0,
            details: "Details",
            currency: "EUR"
        )
        let usdCampaign = Campaign(
            id: "linkedin_0",
            name: "USD Campaign",
            description: "Test",
            monthlyFee: 150.0,
            details: "Details",
            currency: "USD"
        )
        
        appManager.availableChannels = [facebookChannel, linkedinChannel]
        appManager.selectCampaign(eurCampaign, for: facebookChannel)
        appManager.selectCampaign(usdCampaign, for: linkedinChannel)
        
        // When
        let formattedCost = appManager.formattedTotalCost
        
        // Then
        XCTAssertTrue(formattedCost.contains("100") || formattedCost.contains("EUR") || formattedCost.contains("€"))
        XCTAssertTrue(formattedCost.contains("150") || formattedCost.contains("USD") || formattedCost.contains("$"))
        XCTAssertTrue(formattedCost.contains("+")) // Should have separator for multiple currencies
    }
    
    // MARK: - Channel-Campaign Association Tests
    
    func testGetChannelForCampaign() {
        // Given
        let facebookChannel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        let linkedinChannel = Channel(id: "linkedin", channel: "LinkedIn", monthlyFees: [])
        
        let facebookCampaign = Campaign(
            id: "facebook_0",
            name: "Facebook Campaign",
            description: "Test",
            monthlyFee: 100.0,
            details: "Details",
            currency: "EUR"
        )
        let unknownCampaign = Campaign(
            id: "unknown_campaign",
            name: "Unknown Campaign",
            description: "Test",
            monthlyFee: 100.0,
            details: "Details",
            currency: "EUR"
        )
        
        appManager.availableChannels = [facebookChannel, linkedinChannel]
        
        // When/Then
        XCTAssertEqual(appManager.getChannel(for: facebookCampaign)?.id, "facebook")
        XCTAssertNil(appManager.getChannel(for: unknownCampaign))
    }
    
    func testGetPackagesByChannel() {
        // Given
        let facebookChannel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        let linkedinChannel = Channel(id: "linkedin", channel: "LinkedIn", monthlyFees: [])
        
        let facebookCampaign = Campaign(
            id: "facebook_0",
            name: "Facebook Campaign",
            description: "Test",
            monthlyFee: 100.0,
            details: "Details",
            currency: "EUR"
        )
        let linkedinCampaign = Campaign(
            id: "linkedin_0",
            name: "LinkedIn Campaign",
            description: "Test",
            monthlyFee: 150.0,
            details: "Details",
            currency: "USD"
        )
        
        appManager.availableChannels = [facebookChannel, linkedinChannel]
        appManager.selectCampaign(facebookCampaign, for: facebookChannel)
        appManager.selectCampaign(linkedinCampaign, for: linkedinChannel)
        
        // When
        let packages = appManager.getPackagesByChannel()
        
        // Then
        XCTAssertEqual(packages.count, 2)
        
        // Should be sorted by channel name
        XCTAssertEqual(packages[0].channel.name, "Facebook") // F comes before L
        XCTAssertEqual(packages[0].campaign.name, "Facebook Campaign")
        XCTAssertEqual(packages[1].channel.name, "LinkedIn")
        XCTAssertEqual(packages[1].campaign.name, "LinkedIn Campaign")
    }
    
    // MARK: - Validation Tests
    
    func testValidationWithNoCampaigns() {
        // When
        let validation = appManager.validateSelection()
        
        // Then
        XCTAssertFalse(validation.isValid)
        XCTAssertEqual(validation.message, "No campaigns selected")
        XCTAssertFalse(appManager.canProceedToReview)
        XCTAssertFalse(appManager.canSendEmail)
    }
    
    func testValidationWithCampaigns() {
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
        
        appManager.availableChannels = [channel]
        appManager.selectCampaign(campaign, for: channel)
        
        // When
        let validation = appManager.validateSelection()
        
        // Then
        XCTAssertTrue(validation.isValid)
        XCTAssertNil(validation.message)
        XCTAssertTrue(appManager.canProceedToReview)
        XCTAssertTrue(appManager.canSendEmail)
    }
    
    // MARK: - Edge Cases Tests
    
    func testSingleSelectionConstraintAcrossChannels() {
        // Given
        let facebookChannel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        let linkedinChannel = Channel(id: "linkedin", channel: "LinkedIn", monthlyFees: [])
        let twitterChannel = Channel(id: "twitter", channel: "Twitter", monthlyFees: [])
        
        let facebookCampaign1 = Campaign(id: "facebook_0", name: "FB Basic", description: "Test", monthlyFee: 100.0, details: "Details", currency: "EUR")
        let facebookCampaign2 = Campaign(id: "facebook_1", name: "FB Premium", description: "Test", monthlyFee: 200.0, details: "Details", currency: "EUR")
        let linkedinCampaign = Campaign(id: "linkedin_0", name: "LI Basic", description: "Test", monthlyFee: 150.0, details: "Details", currency: "USD")
        let twitterCampaign = Campaign(id: "twitter_0", name: "TW Basic", description: "Test", monthlyFee: 80.0, details: "Details", currency: "USD")
        
        appManager.availableChannels = [facebookChannel, linkedinChannel, twitterChannel]
        
        // When - Select campaigns from multiple channels
        appManager.selectCampaign(facebookCampaign1, for: facebookChannel)
        appManager.selectCampaign(linkedinCampaign, for: linkedinChannel)
        appManager.selectCampaign(twitterCampaign, for: twitterChannel)
        
        // Then - Should have one campaign per channel
        XCTAssertEqual(appManager.selectedCampaigns.count, 3)
        XCTAssertEqual(appManager.getSelectedCampaign(for: facebookChannel)?.id, facebookCampaign1.id)
        XCTAssertEqual(appManager.getSelectedCampaign(for: linkedinChannel)?.id, linkedinCampaign.id)
        XCTAssertEqual(appManager.getSelectedCampaign(for: twitterChannel)?.id, twitterCampaign.id)
        
        // When - Change Facebook selection
        appManager.selectCampaign(facebookCampaign2, for: facebookChannel)
        
        // Then - Should still have 3 campaigns total, but Facebook should be updated
        XCTAssertEqual(appManager.selectedCampaigns.count, 3)
        XCTAssertEqual(appManager.getSelectedCampaign(for: facebookChannel)?.id, facebookCampaign2.id)
        XCTAssertEqual(appManager.getSelectedCampaign(for: linkedinChannel)?.id, linkedinCampaign.id)
        XCTAssertEqual(appManager.getSelectedCampaign(for: twitterChannel)?.id, twitterCampaign.id)
        XCTAssertFalse(appManager.selectedCampaigns.contains(facebookCampaign1))
        XCTAssertTrue(appManager.selectedCampaigns.contains(facebookCampaign2))
    }
    
    func testGetSelectedCampaignForNonExistentChannel() {
        // Given
        let channel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        
        // When/Then
        XCTAssertNil(appManager.getSelectedCampaign(for: channel))
        XCTAssertFalse(appManager.hasSelectedCampaign(for: channel))
    }
    
    // MARK: - Multiple Currency Calculation Tests
    
    func testTotalMonthlyCostWithSameCurrency() {
        // Given
        let facebookChannel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        let linkedinChannel = Channel(id: "linkedin", channel: "LinkedIn", monthlyFees: [])
        
        let campaign1 = Campaign(id: "facebook_0", name: "FB Campaign", description: "Test", monthlyFee: 100.0, details: "Details", currency: "EUR")
        let campaign2 = Campaign(id: "linkedin_0", name: "LI Campaign", description: "Test", monthlyFee: 150.0, details: "Details", currency: "EUR")
        
        appManager.availableChannels = [facebookChannel, linkedinChannel]
        appManager.selectCampaign(campaign1, for: facebookChannel)
        appManager.selectCampaign(campaign2, for: linkedinChannel)
        
        // When
        let totalCost = appManager.totalMonthlyCost
        
        // Then
        XCTAssertEqual(totalCost["EUR"], 250.0) // 100 + 150
        XCTAssertEqual(totalCost.count, 1) // Only one currency
    }
    
    func testAvailableChannelsFiltering() {
        // Given
        let availableChannels1 = [
            AvailableChannel(id: "facebook_location", channel: "Facebook", channelId: "fb123")
        ]
        let availableChannels2 = [
            AvailableChannel(id: "linkedin_age", channel: "LinkedIn", channelId: "li123"),
            AvailableChannel(id: "twitter_age", channel: "Twitter", channelId: "tw123")
        ]
        
        let locationTargeting = TargetingSpecific(id: "location", target: "Location", availableChannels: availableChannels1)
        let ageTargeting = TargetingSpecific(id: "age", target: "Age", availableChannels: availableChannels2)
        
        let allChannels = [
            Channel(id: "facebook", channel: "Facebook", monthlyFees: []),
            Channel(id: "linkedin", channel: "LinkedIn", monthlyFees: []),
            Channel(id: "twitter", channel: "Twitter", monthlyFees: []),
            Channel(id: "instagram", channel: "Instagram", monthlyFees: []) // Not in targeting
        ]
        
        // When - Select only location targeting
        let locationSpecifics: Set<TargetingSpecific> = [locationTargeting]
        appManager.setAvailableChannels(from: locationSpecifics, allChannels: allChannels)
        
        // Then - Should only have Facebook
        XCTAssertEqual(appManager.availableChannels.count, 1)
        XCTAssertEqual(appManager.availableChannels.first?.name, "Facebook")
        
        // When - Select both targeting specifics
        let bothSpecifics: Set<TargetingSpecific> = [locationTargeting, ageTargeting]
        appManager.setAvailableChannels(from: bothSpecifics, allChannels: allChannels)
        
        // Then - Should have Facebook, LinkedIn, and Twitter (but not Instagram)
        XCTAssertEqual(appManager.availableChannels.count, 3)
        let channelNames = Set(appManager.availableChannels.map { $0.name })
        XCTAssertTrue(channelNames.contains("Facebook"))
        XCTAssertTrue(channelNames.contains("LinkedIn"))
        XCTAssertTrue(channelNames.contains("Twitter"))
        XCTAssertFalse(channelNames.contains("Instagram"))
    }
}
