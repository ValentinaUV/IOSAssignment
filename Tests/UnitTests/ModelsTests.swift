import XCTest
@testable import IOSAssignment

final class ModelsTests: XCTestCase {
    
    func testChannelNewStructureCoding() throws {
        // Given - New JSON structure
        let json = """
        {
            "channel": "Facebook",
            "monthly_fees": [
                {
                    "price": 140,
                    "details": ["3-8 listings", "12 optimizations", "Campaign setup"],
                    "currency": "EUR"
                },
                {
                    "price": 280,
                    "details": ["8-15 listings", "24 optimizations", "Premium support"],
                    "currency": "EUR"
                }
            ]
        }
        """.data(using: .utf8)!
        
        // When
        let channel = try JSONDecoder().decode(Channel.self, from: json)
        
        // Then
        XCTAssertEqual(channel.channel, "Facebook")
        XCTAssertEqual(channel.name, "Facebook") // Backwards compatibility
        XCTAssertEqual(channel.id, "facebook")
        XCTAssertEqual(channel.monthlyFees.count, 2)
        XCTAssertEqual(channel.monthlyFees[0].price, 140.0)
        XCTAssertEqual(channel.monthlyFees[0].currency, "EUR")
        XCTAssertEqual(channel.monthlyFees[0].details.count, 3)
        XCTAssertEqual(channel.monthlyFees[1].price, 280.0)
        XCTAssertEqual(channel.monthlyFees[1].details.count, 3)
        
        // Note: This channel won't have channel_id, so accessing getChannelId() should fail
    }
    
    func testChannelWithChannelId() {
        // Test Channel with explicit channel_id
        let channel = Channel(
            id: "facebook",
            channel: "Facebook",
            monthlyFees: [],
            channelId: "0af1bfee844a7003cec5"
        )
        
        XCTAssertEqual(try? channel.getChannelId(), "0af1bfee844a7003cec5")
        XCTAssertEqual(try? channel.getCampaignEndpoint(), "https://api.npoint.io/0af1bfee844a7003cec5")
    }
    
    func testChannelWithoutChannelIdFails() {
        // Test that channels without channel_id fail when accessing channel_id methods
        let channel = Channel(
            id: "facebook",
            channel: "Facebook",
            monthlyFees: []
        )
        
        // These should fail
        XCTAssertThrowsError(try {
            _ = try channel.getChannelId()
        }()) { error in
            print("Expected error for getChannelId: \(error)")
        }
        
        XCTAssertThrowsError(try {
            _ = try channel.getCampaignEndpoint()
        }()) { error in
            print("Expected error for campaignEndpoint: \(error)")
        }
    }
    
    func testMonthlyFeeCoding() throws {
        // Given
        let json = """
        {
            "price": 140,
            "details": ["3-8 listings", "12 optimizations", "Campaign setup"],
            "currency": "EUR"
        }
        """.data(using: .utf8)!
        
        // When
        let monthlyFee = try JSONDecoder().decode(MonthlyFee.self, from: json)
        
        // Then
        XCTAssertEqual(monthlyFee.price, 140.0)
        XCTAssertEqual(monthlyFee.currency, "EUR")
        XCTAssertEqual(monthlyFee.details.count, 3)
        XCTAssertEqual(monthlyFee.details[0], "3-8 listings")
        XCTAssertEqual(monthlyFee.details[1], "12 optimizations")
        XCTAssertEqual(monthlyFee.details[2], "Campaign setup")
    }
    
    func testChannelToCampaignsConversion() {
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
        
        let channel = Channel(
            id: "facebook",
            channel: "Facebook",
            monthlyFees: monthlyFees,
            channelId: "0af1bfee844a7003cec5"
        )
        
        // When
        let campaigns = channel.toCampaigns()
        
        // Then
        XCTAssertEqual(campaigns.count, 2)
        XCTAssertEqual(campaigns[0].id, "facebook_0")
        XCTAssertEqual(campaigns[0].name, "Facebook Package 1")
        XCTAssertEqual(campaigns[0].description, "Monthly package for Facebook")
        XCTAssertEqual(campaigns[0].monthlyFee, 140.0)
        XCTAssertEqual(campaigns[0].currency, "EUR")
        XCTAssertEqual(campaigns[0].details, "3-8 listings, 12 optimizations")
        
        XCTAssertEqual(campaigns[1].id, "facebook_1")
        XCTAssertEqual(campaigns[1].name, "Facebook Package 2")
        XCTAssertEqual(campaigns[1].monthlyFee, 280.0)
        XCTAssertEqual(campaigns[1].details, "8-15 listings, 24 optimizations, Premium support")
        
        // Verify channel_id is properly preserved
        XCTAssertEqual(try? channel.getChannelId(), "0af1bfee844a7003cec5")
        XCTAssertEqual(try? channel.getCampaignEndpoint(), "https://api.npoint.io/0af1bfee844a7003cec5")
    }
    
    func testCampaignWithCurrency() throws {
        // Given
        let json = """
        {
            "id": "1",
            "name": "Test Campaign",
            "description": "Test Description",
            "monthly_fee": 140.50,
            "details": "Feature 1, Feature 2",
            "currency": "EUR"
        }
        """.data(using: .utf8)!
        
        // When
        let campaign = try JSONDecoder().decode(Campaign.self, from: json)
        
        // Then
        XCTAssertEqual(campaign.id, "1")
        XCTAssertEqual(campaign.name, "Test Campaign")
        XCTAssertEqual(campaign.description, "Test Description")
        XCTAssertEqual(campaign.monthlyFee, 140.50)
        XCTAssertEqual(campaign.currency, "EUR")
        XCTAssertEqual(campaign.details, "Feature 1, Feature 2")
        XCTAssertEqual(campaign.detailsArray, ["Feature 1", "Feature 2"])
    }
    
    func testCampaignFormattedPrice() {
        // Given
        let eurCampaign = Campaign(
            id: "1",
            name: "EUR Campaign",
            description: "Test",
            monthlyFee: 140.0,
            details: "Details",
            currency: "EUR"
        )
        
        let usdCampaign = Campaign(
            id: "2",
            name: "USD Campaign",
            description: "Test",
            monthlyFee: 120.0,
            details: "Details",
            currency: "USD"
        )
        
        // Then
        XCTAssertTrue(eurCampaign.formattedPrice.contains("EUR") || eurCampaign.formattedPrice.contains("€"))
        XCTAssertTrue(usdCampaign.formattedPrice.contains("USD") || usdCampaign.formattedPrice.contains("$"))
    }
    
    func testTargetingSpecificNewStructureCoding() throws {
        // Given - New JSON structure
        let json = """
        {
            "target": "Location",
            "available_channels": [
                {
                    "channel": "Facebook",
                    "channel_id": "0af1bfee844a7003cec5"
                },
                {
                    "channel": "Linkedin",
                    "channel_id": "9a464cbf5bf479321862"
                }
            ]
        }
        """.data(using: .utf8)!
        
        // When
        let targeting = try JSONDecoder().decode(TargetingSpecific.self, from: json)
        
        // Then
        XCTAssertEqual(targeting.target, "Location")
        XCTAssertEqual(targeting.name, "Location") // Backwards compatibility
        XCTAssertEqual(targeting.id, "location")
        XCTAssertEqual(targeting.availableChannels.count, 2)
        XCTAssertEqual(targeting.availableChannels[0].channel, "Facebook")
        XCTAssertEqual(targeting.availableChannels[0].channelId, "0af1bfee844a7003cec5")
        XCTAssertEqual(targeting.availableChannels[1].channel, "Linkedin")
        XCTAssertEqual(targeting.availableChannels[1].channelId, "9a464cbf5bf479321862")
    }
    
    func testAvailableChannelToChannelConversion() {
        // Given
        let availableChannel = AvailableChannel(
            id: "facebook_test",
            channel: "Facebook",
            channelId: "0af1bfee844a7003cec5"
        )
        
        // When
        let channel = availableChannel.toChannel()
        
        // Then
        XCTAssertEqual(channel.id, "facebook")
        XCTAssertEqual(channel.channel, "Facebook")
        XCTAssertEqual(channel.name, "Facebook") // Backwards compatibility
        XCTAssertTrue(channel.monthlyFees.isEmpty) // Will be populated later
        XCTAssertEqual(try? channel.getChannelId(), "0af1bfee844a7003cec5")
        XCTAssertEqual(try? channel.getCampaignEndpoint(), "https://api.npoint.io/0af1bfee844a7003cec5")
    }
    
    func testChannelEndpointGenerationWithChannelId() {
        // Given
        let channels = [
            Channel(id: "facebook", channel: "Facebook", monthlyFees: [], channelId: "0af1bfee844a7003cec5"),
            Channel(id: "linkedin", channel: "Linkedin", monthlyFees: [], channelId: "9a464cbf5bf479321862"),
            Channel(id: "twitter", channel: "Twitter", monthlyFees: [], channelId: "66a8bfaafccc4b2c2a9a"),
            Channel(id: "instagram", channel: "Instagram", monthlyFees: [], channelId: "2ebf381815ca49157fd6"),
            Channel(id: "adwords", channel: "AdWords", monthlyFees: [], channelId: "2499f739821b5ab3dcd6"),
            Channel(id: "seo", channel: "SEO", monthlyFees: [], channelId: "9789d17ffaf4432dcce0")
        ]
        
        let expectedEndpoints = [
            "https://api.npoint.io/0af1bfee844a7003cec5",
            "https://api.npoint.io/9a464cbf5bf479321862",
            "https://api.npoint.io/66a8bfaafccc4b2c2a9a",
            "https://api.npoint.io/2ebf381815ca49157fd6",
            "https://api.npoint.io/2499f739821b5ab3dcd6",
            "https://api.npoint.io/9789d17ffaf4432dcce0"
        ]
        
        // Then
        for (index, channel) in channels.enumerated() {
            XCTAssertEqual(try? channel.getCampaignEndpoint(), expectedEndpoints[index])
            XCTAssertEqual(try? channel.getChannelId(), ((try? channel.getCampaignEndpoint()) ?? "" ).replacingOccurrences(of: "https://api.npoint.io/", with: ""))
        }
    }
    
    func testCampaignWithoutCurrency() throws {
        // Given - Campaign without currency (should default to USD)
        let json = """
        {
            "id": "1",
            "name": "Test Campaign",
            "description": "Test Description",
            "monthly_fee": 140.50,
            "details": "Feature 1, Feature 2"
        }
        """.data(using: .utf8)!
        
        // When
        let campaign = try JSONDecoder().decode(Campaign.self, from: json)
        
        // Then
        XCTAssertEqual(campaign.currency, "USD") // Default currency
        XCTAssertTrue(campaign.formattedPrice.contains("USD") || campaign.formattedPrice.contains("$"))
    }
    
    func testComplexChannelStructure() {
        // Given
        let monthlyFees = [
            MonthlyFee(id: "basic", price: 99.0, details: ["Basic feature"], currency: "USD"),
            MonthlyFee(id: "premium", price: 199.0, details: ["Premium feature 1", "Premium feature 2"], currency: "USD"),
            MonthlyFee(id: "enterprise", price: 399.0, details: ["All features", "Priority support", "Custom integration"], currency: "USD")
        ]
        
        let channel = Channel(
            id: "complex_channel",
            channel: "Complex Channel",
            monthlyFees: monthlyFees,
            channelId: "complex123"
        )
        
        // When
        let campaigns = channel.toCampaigns()
        
        // Then
        XCTAssertEqual(campaigns.count, 3)
        XCTAssertEqual(campaigns[0].name, "Complex Channel Package 1")
        XCTAssertEqual(campaigns[1].name, "Complex Channel Package 2")
        XCTAssertEqual(campaigns[2].name, "Complex Channel Package 3")
        
        XCTAssertEqual(campaigns[0].monthlyFee, 99.0)
        XCTAssertEqual(campaigns[1].monthlyFee, 199.0)
        XCTAssertEqual(campaigns[2].monthlyFee, 399.0)
        
        XCTAssertEqual(campaigns[0].details, "Basic feature")
        XCTAssertEqual(campaigns[1].details, "Premium feature 1, Premium feature 2")
        XCTAssertEqual(campaigns[2].details, "All features, Priority support, Custom integration")
        
        // Verify channel_id is preserved
        XCTAssertEqual(try? channel.getChannelId(), "complex123")
        XCTAssertEqual(try? channel.getCampaignEndpoint(), "https://api.npoint.io/complex123")
    }
    
    func testMonthlyFeeFlexiblePricing() throws {
        // Test that MonthlyFee can handle different price formats
        
        // Given - Price as integer
        let jsonInt = """
        {
            "price": 140,
            "details": ["Feature"],
            "currency": "EUR"
        }
        """.data(using: .utf8)!
        
        // When
        let feeInt = try JSONDecoder().decode(MonthlyFee.self, from: jsonInt)
        
        // Then
        XCTAssertEqual(feeInt.price, 140.0)
        
        // Given - Price as string
        let jsonString = """
        {
            "price": "140.50",
            "details": ["Feature"],
            "currency": "EUR"
        }
        """.data(using: .utf8)!
        
        // When
        let feeString = try JSONDecoder().decode(MonthlyFee.self, from: jsonString)
        
        // Then
        XCTAssertEqual(feeString.price, 140.50)
    }
    
    func testCampaignFlexiblePricing() throws {
        // Test that Campaign can handle different price formats
        
        // Given - Price as integer
        let jsonInt = """
        {
            "id": "1",
            "name": "Test",
            "description": "Test",
            "monthly_fee": 140,
            "details": "Details"
        }
        """.data(using: .utf8)!
        
        // When
        let campaignInt = try JSONDecoder().decode(Campaign.self, from: jsonInt)
        
        // Then
        XCTAssertEqual(campaignInt.monthlyFee, 140.0)
        
        // Given - Price as string
        let jsonString = """
        {
            "id": "1",
            "name": "Test",
            "description": "Test",
            "monthly_fee": "140.50",
            "details": "Details"
        }
        """.data(using: .utf8)!
        
        // When
        let campaignString = try JSONDecoder().decode(Campaign.self, from: jsonString)
        
        // Then
        XCTAssertEqual(campaignString.monthlyFee, 140.50)
    }
    
    func testCampaignIdGeneration() throws {
        // Test that Campaign generates ID if not provided
        
        // Given - No ID in JSON
        let json = """
        {
            "name": "Test Campaign",
            "description": "Test",
            "monthly_fee": 100,
            "details": "Details"
        }
        """.data(using: .utf8)!
        
        // When
        let campaign = try JSONDecoder().decode(Campaign.self, from: json)
        
        // Then
        XCTAssertFalse(campaign.id.isEmpty)
        XCTAssertNotNil(UUID(uuidString: campaign.id)) // Should be a valid UUID
    }
    
    func testCampaignDetailsArray() {
        // Given
        let campaign = Campaign(
            id: "1",
            name: "Test",
            description: "Test",
            monthlyFee: 100.0,
            details: "Feature 1, Feature 2, Feature 3",
            currency: "EUR"
        )
        
        // When
        let detailsArray = campaign.detailsArray
        
        // Then
        XCTAssertEqual(detailsArray.count, 3)
        XCTAssertEqual(detailsArray[0], "Feature 1")
        XCTAssertEqual(detailsArray[1], "Feature 2")
        XCTAssertEqual(detailsArray[2], "Feature 3")
    }
    
    func testAvailableChannelUniqueId() {
        // Test that AvailableChannel creates unique IDs
        let channel1 = AvailableChannel(
            id: "facebook_location",
            channel: "Facebook",
            channelId: "channel123"
        )
        
        let channel2 = AvailableChannel(
            id: "facebook_age",
            channel: "Facebook",
            channelId: "channel456"
        )
        
        XCTAssertNotEqual(channel1.id, channel2.id)
        XCTAssertEqual(channel1.channel, channel2.channel) // Same channel name
        XCTAssertNotEqual(channel1.channelId, channel2.channelId) // Different channel IDs
    }
    
    func testTargetingSpecificIdGeneration() {
        // Test that TargetingSpecific generates proper IDs
        let targeting1 = TargetingSpecific(
            id: "location_based",
            target: "Location Based",
            availableChannels: []
        )
        
        let targeting2 = TargetingSpecific(
            id: "age_group",
            target: "Age Group",
            availableChannels: []
        )
        
        XCTAssertEqual(targeting1.target, "Location Based")
        XCTAssertEqual(targeting1.name, "Location Based") // Backwards compatibility
        XCTAssertEqual(targeting1.id, "location_based")
        
        XCTAssertEqual(targeting2.target, "Age Group")
        XCTAssertEqual(targeting2.id, "age_group")
        
        XCTAssertNotEqual(targeting1.id, targeting2.id)
    }
    
    func testChannelIdRequirementEnforcement() {
        // Test that the system properly enforces channel_id requirements
        
        // Valid channel with channel_id should work
        let validChannel = Channel(
            id: "facebook",
            channel: "Facebook",
            monthlyFees: [],
            channelId: "0af1bfee844a7003cec5"
        )
        
        XCTAssertEqual(try? validChannel.getChannelId(), "0af1bfee844a7003cec5")
        XCTAssertEqual(try? validChannel.getCampaignEndpoint(), "https://api.npoint.io/0af1bfee844a7003cec5")
        
        // Invalid channel without channel_id should fail
        let invalidChannel = Channel(
            id: "facebook",
            channel: "Facebook",
            monthlyFees: []
        )
        
        XCTAssertThrowsError(try {
            _ = try invalidChannel.getChannelId()
        }())
        
        XCTAssertThrowsError(try {
            _ = try invalidChannel.getCampaignEndpoint()
        }())
    }
    
    func testChannelIdFromAvailableChannelFlow() {
        // Test the complete flow from AvailableChannel to Channel
        
        // Given - AvailableChannel from API response
        let availableChannel = AvailableChannel(
            id: "facebook_location_targeting",
            channel: "Facebook",
            channelId: "0af1bfee844a7003cec5"
        )
        
        // When - Convert to Channel
        let channel = availableChannel.toChannel()
        
        // Then - Channel should have all correct properties
        XCTAssertEqual(channel.id, "facebook")
        XCTAssertEqual(channel.channel, "Facebook")
        XCTAssertEqual(channel.name, "Facebook")
        XCTAssertTrue(channel.monthlyFees.isEmpty)
        XCTAssertEqual(try? channel.getChannelId(), "0af1bfee844a7003cec5")
        XCTAssertEqual(try? channel.getCampaignEndpoint(), "https://api.npoint.io/0af1bfee844a7003cec5")
        
        // When - Add monthly fees to create detailed channel
        let monthlyFees = [
            MonthlyFee(id: "basic", price: 100.0, details: ["Basic features"], currency: "EUR")
        ]
        
        let detailedChannel = Channel(
            id: channel.id,
            channel: channel.channel,
            monthlyFees: monthlyFees,
            channelId: (try? channel.getChannelId()) ?? ""
        )
        
        // Then - Detailed channel should preserve channel_id
        XCTAssertEqual(try? detailedChannel.getChannelId(), "0af1bfee844a7003cec5")
        XCTAssertEqual(try? detailedChannel.getCampaignEndpoint(), "https://api.npoint.io/0af1bfee844a7003cec5")
        XCTAssertEqual(detailedChannel.monthlyFees.count, 1)
        
        // When - Convert to campaigns
        let campaigns = detailedChannel.toCampaigns()
        
        // Then - Campaigns should be properly generated
        XCTAssertEqual(campaigns.count, 1)
        XCTAssertEqual(campaigns[0].id, "facebook_0")
        XCTAssertEqual(campaigns[0].name, "Facebook Package 1")
        XCTAssertEqual(campaigns[0].monthlyFee, 100.0)
        XCTAssertEqual(campaigns[0].currency, "EUR")
    }
    
    func testChannelIdConsistencyAcrossOperations() {
        // Test that channel_id remains consistent across all operations
        
        let originalChannelId = "0af1bfee844a7003cec5"
        
        // Create initial available channel
        let availableChannel = AvailableChannel(
            id: "facebook_test",
            channel: "Facebook",
            channelId: originalChannelId
        )
        
        // Convert to basic channel
        let basicChannel = availableChannel.toChannel()
        XCTAssertEqual(try? basicChannel.getChannelId(), originalChannelId)
        
        // Add monthly fees
        let monthlyFees = [
            MonthlyFee(id: "fee1", price: 100.0, details: ["Feature 1"], currency: "EUR"),
            MonthlyFee(id: "fee2", price: 200.0, details: ["Feature 2"], currency: "EUR")
        ]
        
        let detailedChannel = Channel(
            id: basicChannel.id,
            channel: basicChannel.channel,
            monthlyFees: monthlyFees,
            channelId: (try? basicChannel.getChannelId()) ?? ""
        )
        
        // Verify consistency
        XCTAssertEqual(try? detailedChannel.getChannelId(), originalChannelId)
        XCTAssertEqual(try? detailedChannel.getCampaignEndpoint(), "https://api.npoint.io/\(originalChannelId)")
        
        // Convert to campaigns and back
        let campaigns = detailedChannel.toCampaigns()
        XCTAssertEqual(campaigns.count, 2)
        
        // Verify campaigns have correct channel association
        for campaign in campaigns {
            XCTAssertTrue(campaign.id.hasPrefix("facebook_"))
        }
        
        // All operations should maintain the same channel_id
        XCTAssertEqual(availableChannel.channelId, originalChannelId)
        XCTAssertEqual(try? basicChannel.getChannelId(), originalChannelId)
        XCTAssertEqual(try? detailedChannel.getChannelId(), originalChannelId)
    }
}
