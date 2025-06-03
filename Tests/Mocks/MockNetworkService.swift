import Foundation
@testable import IOSAssignment

class MockNetworkService: NetworkServiceProtocol {
    var shouldFail = false
    var targetingResponse: TargetingResponse?
    var channelDetailsResponse: Channel?
    
    func fetchTargetingData() async throws -> TargetingResponse {
        if shouldFail {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        
        // Return mock response or throw error if no mock set
        if let response = targetingResponse {
            return response
        } else {
            throw NSError(domain: "TestError", code: 2, userInfo: [NSLocalizedDescriptionKey: "No mock targeting response set"])
        }
    }
    
    func fetchChannelDetails(for channel: Channel) async throws -> Channel {
        if shouldFail {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        
        // Return mock channel details or the original channel
        return channelDetailsResponse ?? channel
    }
}
