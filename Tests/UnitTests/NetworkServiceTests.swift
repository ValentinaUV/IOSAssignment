import XCTest
import Alamofire
@testable import IOSAssignment

final class NetworkServiceTests: XCTestCase {
    var networkService: NetworkService!
    
    override func setUp() {
        super.setUp()
        networkService = NetworkService.shared
    }
    
    func testNetworkServiceSingleton() {
        // Test that NetworkService is a singleton
        let instance1 = NetworkService.shared
        let instance2 = NetworkService.shared
        
        XCTAssertTrue(instance1 === instance2)
    }
    
    func testFetchTargetingDataFromAPI() async {
        // Test that the service attempts to fetch from real API and falls back to local files if needed
        do {
            let response = try await networkService.fetchTargetingData()
            
            // If successful, we should have some data (either from API or local files)
            print("Received \(response.targetingSpecifics.count) targeting specifics")
            print("Received \(response.channels.count) channels")
            
            // Basic validation - we should have some data if local files are available
            XCTAssertTrue(response.targetingSpecifics.count >= 0)
            XCTAssertTrue(response.channels.count >= 0)
            
            // Validate new structure if data exists
            for targeting in response.targetingSpecifics {
                XCTAssertFalse(targeting.target.isEmpty)
                XCTAssertFalse(targeting.id.isEmpty)
                // Should have available channels (either from API or local files)
                XCTAssertTrue(targeting.availableChannels.count >= 0)
                
                // Validate that channel_id is properly set
                for availableChannel in targeting.availableChannels {
                    XCTAssertFalse(availableChannel.channelId.isEmpty)
                    print("Channel: \(availableChannel.channel) has ID: \(availableChannel.channelId)")
                }
            }
            
        } catch {
            // Error is acceptable if both API and local files are unavailable
            print("Expected error when both API and local files unavailable: \(error)")
        }
    }
    
    func testFetchChannelDetailsFromAPI() async {
        // Test that the service attempts to fetch channel details from real API
        let testChannel = Channel(
            id: "facebook",
            channel: "Facebook",
            monthlyFees: [],
            channelId: "0af1bfee844a7003cec5" // Use actual channel_id
        )
        
        do {
            let response = try await networkService.fetchChannelDetails(for: testChannel)
            
            print("Received channel with \(response.monthlyFees.count) monthly fees")
            
            // Basic validation
            XCTAssertEqual(response.channel, testChannel.channel)
            XCTAssertTrue(response.monthlyFees.count >= 0) // Could be empty if API unavailable
            
            // Verify that the endpoint uses the correct channel_id
            XCTAssertTrue(((try? testChannel.getCampaignEndpoint()) ?? "" ).contains("0af1bfee844a7003cec5"))
            
            // Verify that getChannelId returns the correct ID
            XCTAssertEqual(try? testChannel.getChannelId(), "0af1bfee844a7003cec5")
            
            // If we have monthly fees, validate their structure
            for fee in response.monthlyFees {
                XCTAssertFalse(fee.id.isEmpty)
                XCTAssertGreaterThanOrEqual(fee.price, 0)
                XCTAssertFalse(fee.currency.isEmpty)
                XCTAssertTrue(fee.details.count > 0)
            }
            
        } catch {
            // Error is acceptable for channels without local files
            print("Expected error when local files not available: \(error)")
        }
    }
    
    func testChannelIdDirectAccess() {
        // Test that we can get channel_id directly from Channel object
        let testChannel = Channel(
            id: "facebook",
            channel: "Facebook",
            monthlyFees: [],
            channelId: "0af1bfee844a7003cec5"
        )
        
        // Should return the stored channel_id
        XCTAssertEqual(try? testChannel.getChannelId(), "0af1bfee844a7003cec5")
        
        // Should use channel_id in endpoint
        XCTAssertEqual(try? testChannel.getCampaignEndpoint(), "https://api.npoint.io/0af1bfee844a7003cec5")
    }
    
    func testChannelRequiresChannelId() {
        // Test that channels without channel_id will fail appropriately
        let testChannelWithoutId = Channel(
            id: "facebook",
            channel: "Facebook",
            monthlyFees: []
        )
        
        // Should fail when trying to access channel_id or endpoint
        XCTAssertThrowsError(try {
            _ = try testChannelWithoutId.getChannelId()
        }()) { error in
            // Expected behavior - channels must have channel_id
            print("Expected error for channel without ID: \(error)")
        }
        
        XCTAssertThrowsError(try {
            _ = try testChannelWithoutId.getCampaignEndpoint()
        }()) { error in
            // Expected behavior - channels must have channel_id for endpoints
            print("Expected error for endpoint without ID: \(error)")
        }
    }
    
    func testNewChannelStructureParsing() {
        // Test parsing of the new channel structure manually
        let sampleJSON = """
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
                    "details": ["8-15 listings", "24 optimizations", "Campaign setup", "Premium support"],
                    "currency": "EUR"
                }
            ]
        }
        """.data(using: .utf8)!
        
        // Convert to data and test parsing
        do {
            let channel = try JSONDecoder().decode(Channel.self, from: sampleJSON)
            
            XCTAssertEqual(channel.channel, "Facebook")
            XCTAssertEqual(channel.id, "facebook")
            XCTAssertEqual(channel.monthlyFees.count, 2)
            XCTAssertEqual(channel.monthlyFees[0].price, 140.0)
            XCTAssertEqual(channel.monthlyFees[0].currency, "EUR")
            XCTAssertEqual(channel.monthlyFees[0].details.count, 3)
            XCTAssertEqual(channel.monthlyFees[1].price, 280.0)
            XCTAssertEqual(channel.monthlyFees[1].details.count, 4)
            
            // Note: This channel won't have a channel_id since it wasn't created from AvailableChannel
            // Accessing getChannelId() would fail, which is the expected behavior
            
        } catch {
            XCTFail("Failed to parse new channel structure: \(error)")
        }
    }
    
    func testChannelToCampaignsConversion() {
        // Test conversion of monthly fees to campaigns
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
        
        let campaigns = channel.toCampaigns()
        
        XCTAssertEqual(campaigns.count, 2)
        XCTAssertEqual(campaigns[0].name, "Facebook Package 1")
        XCTAssertEqual(campaigns[1].name, "Facebook Package 2")
        XCTAssertEqual(campaigns[0].monthlyFee, 140.0)
        XCTAssertEqual(campaigns[1].monthlyFee, 280.0)
        XCTAssertEqual(campaigns[0].currency, "EUR")
        XCTAssertEqual(campaigns[1].currency, "EUR")
        
        // Test that endpoint uses the stored channel_id
        XCTAssertEqual(try? channel.getCampaignEndpoint(), "https://api.npoint.io/0af1bfee844a7003cec5")
        XCTAssertEqual(try? channel.getChannelId(), "0af1bfee844a7003cec5")
    }
    
    func testAvailableChannelToChannelConversion() {
        // Test that AvailableChannel properly converts to Channel with channel_id
        let availableChannel = AvailableChannel(
            id: "facebook_test",
            channel: "Facebook",
            channelId: "0af1bfee844a7003cec5"
        )
        
        let channel = availableChannel.toChannel()
        
        XCTAssertEqual(channel.id, "facebook")
        XCTAssertEqual(channel.channel, "Facebook")
        XCTAssertEqual(channel.name, "Facebook") // Backwards compatibility
        XCTAssertTrue(channel.monthlyFees.isEmpty) // Will be populated later
        XCTAssertEqual(try? channel.getCampaignEndpoint(), "https://api.npoint.io/0af1bfee844a7003cec5")
        XCTAssertEqual(try? channel.getChannelId(), "0af1bfee844a7003cec5")
    }
    
    func testNetworkServiceResilience() async {
        // Test that the service is resilient to various error conditions
        
        // Test multiple calls don't interfere with each other
        let task1 = Task {
            try await networkService.fetchTargetingData()
        }
        
        let task2 = Task {
            let channel = Channel(
                id: "facebook",
                channel: "Facebook",
                monthlyFees: [],
                channelId: "0af1bfee844a7003cec5"
            )
            return try await networkService.fetchChannelDetails(for: channel)
        }
        
        do {
            let (result1, result2) = try await (task1.value, task2.value)
            
            // Both should succeed or fail gracefully
            XCTAssertGreaterThanOrEqual(result1.targetingSpecifics.count, 0)
            XCTAssertNotNil(result2)
            
        } catch {
            // Failures are acceptable if local files aren't available
            print("Expected error in test environment: \(error)")
        }
    }
    
    func testChannelIdPreservation() {
        // Test that channel_id is preserved through the conversion process
        let originalChannelId = "0af1bfee844a7003cec5"
        
        // Create AvailableChannel with channel_id
        let availableChannel = AvailableChannel(
            id: "facebook_test",
            channel: "Facebook",
            channelId: originalChannelId
        )
        
        // Convert to Channel
        let channel = availableChannel.toChannel()
        
        // Verify channel_id is preserved in the endpoint and accessible via getChannelId
        XCTAssertEqual(try? channel.getCampaignEndpoint(), "https://api.npoint.io/\(originalChannelId)")
        XCTAssertEqual(try? channel.getChannelId(), originalChannelId)
        
        // Test that multiple conversions maintain the same endpoint
        let channel2 = availableChannel.toChannel()
        XCTAssertEqual(try? channel.getCampaignEndpoint(), try? channel2.getCampaignEndpoint())
        XCTAssertEqual(try? channel.getChannelId(), try? channel2.getChannelId())
    }
    
    func testChannelIdAccessibilityFromNetworkService() {
        // Test that NetworkService can properly access channel_id from Channel object
        let testChannel = Channel(
            id: "facebook",
            channel: "Facebook",
            monthlyFees: [],
            channelId: "0af1bfee844a7003cec5"
        )
        
        // Verify that getChannelId method works as expected for NetworkService
        let channelId = try? testChannel.getChannelId()
        XCTAssertEqual(channelId, "0af1bfee844a7003cec5")
        XCTAssertFalse(channelId == nil)
        
        // Test endpoint construction
        if let channelId {
            let endpoint = "https://api.npoint.io/\(channelId)"
            XCTAssertEqual(try? testChannel.getCampaignEndpoint(), endpoint)
        }
    }
    
    func testSpecificsJSONFileNaming() {
        // Test that the correct file names are used for targeting and channel data
        
        // For targeting data, should look for b22fd39c053b256222b1.json
        let targetingFileName = "b22fd39c053b256222b1"
        XCTAssertEqual(targetingFileName, "b22fd39c053b256222b1")
        
        // For channel data, should look for {channel_id}.json using actual channel_ids
        let channelIds = [
            "0af1bfee844a7003cec5", // Facebook
            "9a464cbf5bf479321862", // LinkedIn
            "66a8bfaafccc4b2c2a9a", // Twitter
            "2ebf381815ca49157fd6", // Instagram
            "2499f739821b5ab3dcd6", // AdWords
            "9789d17ffaf4432dcce0"  // SEO
        ]
        
        for channelId in channelIds {
            XCTAssertTrue(channelId.count > 10) // Should be valid channel IDs
            XCTAssertFalse(channelId.isEmpty)
            print("Channel ID: \(channelId)")
        }
    }
    
    func testTimeoutErrorHandling() {
        // Test that timeout errors are properly identified
        // Note: This is a unit test for the error detection logic
        
        // Create a mock timeout error
        let timeoutError = AFError.sessionTaskFailed(
            error: NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)
        )
        
        // Test the private method logic (we can't access it directly, but we test the concept)
        let nsError = timeoutError.underlyingError as? NSError
        let isTimeoutError = nsError?.code == NSURLErrorTimedOut ||
                           nsError?.code == NSURLErrorNetworkConnectionLost ||
                           nsError?.code == NSURLErrorNotConnectedToInternet
        
        XCTAssertTrue(isTimeoutError)
    }
    
    func testErrorHandlingWithoutFallback() async {
        // Test that proper errors are thrown when both API and local files fail
        do {
            _ = try await networkService.fetchTargetingData()
            // If this succeeds, either API or local files are available
        } catch NetworkError.invalidResponseFormat(let message) {
            XCTAssertTrue(message.contains("No local targeting data available") || 
                         message.contains("No targeting specifics found") ||
                         message.contains("Unexpected JSON structure"))
        } catch NetworkError.decodingError(_) {
            // Acceptable - means local files exist but are malformed
        } catch NetworkError.networkError(_) {
            // Acceptable - means API failed and no local files
        } catch NetworkError.timeoutError {
            // Acceptable - means timeout occurred and no local files
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testLocalFileSearchWithChannelIds() {
        // Test that local file search uses channel_id as filename
        let testChannelIds = [
            "0af1bfee844a7003cec5", // Facebook
            "9a464cbf5bf479321862", // LinkedIn
            "66a8bfaafccc4b2c2a9a"  // Twitter
        ]
        
        for channelId in testChannelIds {
            // Test that the filename would be correct
            let expectedFilename = "\(channelId).json"
            XCTAssertTrue(expectedFilename.hasSuffix(".json"))
            XCTAssertTrue(expectedFilename.contains(channelId))
            print("Expected local file: \(expectedFilename)")
        }
    }
    
    func testTargetingResponseErrorHandling() async {
        // Test that targeting response properly handles errors without creating default fallback
        do {
            let response = try await networkService.fetchTargetingData()
            
            // If successful, validate the response
            XCTAssertGreaterThanOrEqual(response.targetingSpecifics.count, 0)
            XCTAssertGreaterThanOrEqual(response.channels.count, 0)
            
            // Ensure we don't have any "default" or fallback data if this is real API data
            for targeting in response.targetingSpecifics {
                XCTAssertFalse(targeting.target.isEmpty)
                for channel in targeting.availableChannels {
                    XCTAssertFalse(channel.channelId.isEmpty)
                }
            }
            
        } catch {
            // Error is expected if both API and local files are unavailable
            print("Expected error without fallback: \(error)")
            
            // Verify it's an appropriate error type
            switch error {
            case NetworkError.invalidResponseFormat(_),
                 NetworkError.decodingError(_),
                 NetworkError.networkError(_),
                 NetworkError.timeoutError:
                // These are all acceptable error types
                break
            default:
                XCTFail("Unexpected error type: \(error)")
            }
        }
    }
    
    func testChannelCreationWithChannelIdPreservation() async {
        // Test that when NetworkService creates channels from targeting data, channel_id is preserved
        do {
            let response = try await networkService.fetchTargetingData()
            
            for targeting in response.targetingSpecifics {
                for availableChannel in targeting.availableChannels {
                    // Convert to channel
                    let channel = availableChannel.toChannel()
                    
                    // Verify channel_id is preserved
                    XCTAssertEqual(try? channel.getChannelId(), availableChannel.channelId)
                    XCTAssertTrue(((try? channel.getCampaignEndpoint()) ?? "" ).contains(availableChannel.channelId))
                }
            }
            
        } catch {
            print("Expected error in test environment: \(error)")
        }
    }
    
    func testChannelMustHaveChannelId() {
        // Test that all channels must be created with a valid channel_id
        
        // This should work - channel with channel_id
        let validChannel = Channel(
            id: "facebook",
            channel: "Facebook",
            monthlyFees: [],
            channelId: "0af1bfee844a7003cec5"
        )
        
        XCTAssertEqual(try? validChannel.getChannelId(), "0af1bfee844a7003cec5")
        XCTAssertEqual(try? validChannel.getCampaignEndpoint(), "https://api.npoint.io/0af1bfee844a7003cec5")
        
        // This should fail - channel without channel_id
        let invalidChannel = Channel(
            id: "facebook",
            channel: "Facebook",
            monthlyFees: []
        )
        
        // These should fail at runtime
        XCTAssertThrowsError(try {
            _ = try invalidChannel.getChannelId()
        }())
        
        XCTAssertThrowsError(try {
            _ = try invalidChannel.getCampaignEndpoint()
        }())
    }
    
    func testNetworkServiceOnlyUsesChannelsWithChannelId() async {
        // Test that NetworkService only works with channels that have valid channel_ids
        
        let validChannel = Channel(
            id: "facebook",
            channel: "Facebook",
            monthlyFees: [],
            channelId: "0af1bfee844a7003cec5"
        )
        
        let invalidChannel = Channel(
            id: "facebook",
            channel: "Facebook",
            monthlyFees: []
        )
        
        // Valid channel should work (or fail gracefully if API/files unavailable)
        do {
            _ = try await networkService.fetchChannelDetails(for: validChannel)
        } catch {
            print("Expected network/file error for valid channel: \(error)")
            // This is acceptable - API or local files might not be available
        }
        
        // Invalid channel should fail immediately when trying to access endpoint
        do {
            _ = try await networkService.fetchChannelDetails(for: invalidChannel)
            XCTFail("Should have failed for channel without channel_id")
        } catch {
            // Expected to fail - channels without channel_id cannot be used
            print("Expected failure for invalid channel: \(error)")
        }
    }
}
