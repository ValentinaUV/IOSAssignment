import Foundation
import Alamofire

protocol NetworkServiceProtocol: AnyObject {
    func fetchTargetingData() async throws -> TargetingResponse
    func fetchChannelDetails(for channel: Channel) async throws -> Channel
}

class NetworkService: NetworkServiceProtocol {
    static let shared = NetworkService()
    
    private let session: Session
    
    private init() {
        // Create custom configuration with longer timeouts for real API calls
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 3.0
        configuration.timeoutIntervalForResource = 6.0
        configuration.waitsForConnectivity = true
        
        // Add common headers
        configuration.httpAdditionalHeaders = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        
        // Create session with custom configuration
        self.session = Session(configuration: configuration)
    }
    
    func fetchTargetingData() async throws -> TargetingResponse {
        print("🚀 Starting request to targeting endpoint...")
        
        do {
            return try await withCheckedThrowingContinuation { continuation in
                let request = session.request(
                    "https://api.npoint.io/b22fd39c053b256222b1",
                    method: .get,
                    headers: [
                        "Accept": "application/json",
                        "Cache-Control": "no-cache"
                    ]
                )
                
                request
                    .validate(statusCode: 200..<300)
                    .responseData { response in
                        print("📡 Response status code: \(response.response?.statusCode ?? -1)")
                        print("📡 Response headers: \(response.response?.allHeaderFields ?? [:])")
                        
                        switch response.result {
                        case .success(let data):
                            print("✅ Received data: \(data.count) bytes")
                            print("📄 Raw response: \(String(data: data, encoding: .utf8) ?? "Invalid UTF-8")")
                            
                            do {
                                let targetingResponse = try self.parseTargetingResponse(from: data)
                                print("✅ Successfully parsed targeting response")
                                continuation.resume(returning: targetingResponse)
                            } catch {
                                print("❌ Failed to parse targeting response: \(error)")
                                continuation.resume(throwing: NetworkError.decodingError(error))
                            }
                            
                        case .failure(let error):
                            print("❌ Network request failed: \(error)")
                            print("❌ Error description: \(error.localizedDescription)")
                            
                            // Check if it's a timeout error
                            if self.isTimeoutError(error) {
                                print("⏰ Timeout detected, attempting to load from local file...")
                                continuation.resume(throwing: NetworkError.timeoutError)
                            } else {
                                continuation.resume(throwing: NetworkError.networkError(error))
                            }
                        }
                    }
            }
        } catch NetworkError.timeoutError {
            print("⚠️ API request timed out, loading from local file b22fd39c053b256222b1.json...")
            return try await loadTargetingFromLocalFile()
        } catch {
            print("⚠️ API request failed: \(error), attempting to load from local file...")
            return try await loadTargetingFromLocalFile()
        }
    }
    
    func fetchChannelDetails(for channel: Channel) async throws -> Channel {
        // Use the channel's campaign endpoint which already contains the correct channel_id
        guard let endpoint = try? channel.getCampaignEndpoint() else {
            throw ChannelError.campaignEndpointError
        }
        
        print("🚀 Starting request to channel endpoint: \(endpoint)")
        
        // Get channel_id directly from the channel object
        guard let channelId = try? channel.getChannelId() else {
            throw ChannelError.channelIdNotFound
        }
        
        do {
            return try await withCheckedThrowingContinuation { continuation in
                let request = session.request(
                    endpoint,
                    method: .get,
                    headers: [
                        "Accept": "application/json",
                        "Cache-Control": "no-cache"
                    ]
                )
                
                request
                    .validate(statusCode: 200..<300)
                    .responseData { response in
                        print("📡 Channel response status code: \(response.response?.statusCode ?? -1)")
                        
                        switch response.result {
                        case .success(let data):
                            print("✅ Received channel data: \(data.count) bytes")
                            print("📄 Raw channel response: \(String(data: data, encoding: .utf8) ?? "Invalid UTF-8")")
                            
                            do {
                                let detailedChannel = try self.parseChannelResponse(from: data, originalChannel: channel)
                                print("✅ Successfully parsed channel response")
                                continuation.resume(returning: detailedChannel)
                            } catch {
                                print("❌ Failed to parse channel response: \(error)")
                                continuation.resume(throwing: NetworkError.decodingError(error))
                            }
                            
                        case .failure(let error):
                            print("❌ Channel network request failed: \(error)")
                            
                            // Check if it's a timeout error
                            if self.isTimeoutError(error) {
                                print("⏰ Timeout detected, attempting to load from local file...")
                                continuation.resume(throwing: NetworkError.timeoutError)
                            } else {
                                continuation.resume(throwing: NetworkError.networkError(error))
                            }
                        }
                    }
            }
        } catch NetworkError.timeoutError {
            print("⚠️ Channel API request timed out, loading from local file \(channelId).json...")
            return try await loadChannelFromLocalFile(channelId: channelId, originalChannel: channel)
        } catch {
            print("⚠️ Channel API request failed: \(error), attempting to load from local file...")
            return try await loadChannelFromLocalFile(channelId: channelId, originalChannel: channel)
        }
    }
    
    // MARK: - Helper Methods
    
    private func isTimeoutError(_ error: AFError) -> Bool {
        switch error {
        case .sessionTaskFailed(let sessionError):
            let nsError = sessionError as NSError
            return nsError.code == NSURLErrorTimedOut || 
                   nsError.code == NSURLErrorNetworkConnectionLost ||
                   nsError.code == NSURLErrorNotConnectedToInternet
        default:
            return false
        }
    }
    
    // MARK: - Local File Loading Methods
    
    private func loadTargetingFromLocalFile() async throws -> TargetingResponse {
        print("📁 Loading targeting data from local file b22fd39c053b256222b1.json...")
        
        if let targetingData = loadJSONFromSpecificsFolder(filename: "b22fd39c053b256222b1") {
            print("✅ Found b22fd39c053b256222b1.json in Specifics-JSON folder")
            do {
                let response = try parseTargetingResponse(from: targetingData)
                print("✅ Successfully loaded targeting data from local file")
                return response
            } catch {
                print("❌ Failed to parse local targeting data: \(error)")
                throw NetworkError.decodingError(error)
            }
        } else {
            print("❌ Could not find b22fd39c053b256222b1.json in Specifics-JSON folder")
            throw NetworkError.invalidResponseFormat("No local targeting data available")
        }
    }
    
    private func loadChannelFromLocalFile(channelId: String, originalChannel: Channel) async throws -> Channel {
        print("📁 Loading channel details from local file \(channelId).json...")
        
        if let channelData = loadJSONFromSpecificsFolder(filename: channelId) {
            print("✅ Found \(channelId).json in Specifics-JSON folder")
            do {
                let detailedChannel = try parseChannelResponse(from: channelData, originalChannel: originalChannel)
                print("✅ Successfully loaded channel data from local file: \(channelId).json")
                return detailedChannel
            } catch {
                print("❌ Failed to parse local channel data: \(error)")
                throw NetworkError.decodingError(error)
            }
        } else {
            print("❌ Could not find \(channelId).json in Specifics-JSON folder")
            print("⚠️ Returning original channel with empty fees")
            return originalChannel
        }
    }
    
    private func loadJSONFromSpecificsFolder(filename: String) -> Data? {
        print("📂 Attempting to load: \(filename).json from Specifics-JSON folder...")
        
        // Try different possible paths for Specifics-JSON folder
        let possiblePaths = [
            "Specifics-JSON/\(filename)",
            "Specifics-Json/\(filename)", // Alternative capitalization
            "specifics-json/\(filename)", // Lowercase
            "Data/Specifics-JSON/\(filename)",
            "Resources/Specifics-JSON/\(filename)"
        ]
        
        for path in possiblePaths {
            if let url = Bundle.main.url(forResource: path, withExtension: "json") {
                print("✅ Found file at path: \(path).json")
                do {
                    let data = try Data(contentsOf: url)
                    print("✅ Successfully loaded \(data.count) bytes from \(path).json")
                    return data
                } catch {
                    print("❌ Failed to read data from \(path).json: \(error)")
                }
            }
        }
        
        // Also try direct file access in case it's in the root
        if let url = Bundle.main.url(forResource: filename, withExtension: "json") {
            print("✅ Found file directly: \(filename).json")
            do {
                let data = try Data(contentsOf: url)
                print("✅ Successfully loaded \(data.count) bytes from \(filename).json")
                return data
            } catch {
                print("❌ Failed to read data from \(filename).json: \(error)")
            }
        }
        
        print("❌ Could not find \(filename).json in any expected location")
        print("📂 Searched paths: \(possiblePaths.map { "\($0).json" })")
        return nil
    }
    
    // MARK: - Parsing Methods
    
    private func parseTargetingResponse(from data: Data) throws -> TargetingResponse {
        print("🔍 Attempting to parse targeting response with new structure...")
        
        // First, let's see what the raw JSON looks like
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📄 Raw JSON: \(jsonString)")
        }
        
        do {
            // Try to decode with the TargetingResponse structure which handles both formats
            let targetingResponse = try JSONDecoder().decode(TargetingResponse.self, from: data)
            print("✅ Successfully parsed targeting response with new structure")
            print("📊 Found \(targetingResponse.targetingSpecifics.count) targeting specifics")
            print("📊 Found \(targetingResponse.channels.count) channels")
            
            return targetingResponse
        } catch {
            print("❌ Failed to parse with new structure, trying manual parsing: \(error)")
            
            // Fallback to manual parsing
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                print("📊 JSON object type: \(type(of: json))")
                
                if let jsonArray = json as? [Any] {
                    print("📊 JSON is an array with \(jsonArray.count) elements")
                    return try parseTargetingFromArray(jsonArray)
                } else {
                    print("❌ Unexpected JSON structure")
                    throw NetworkError.invalidResponseFormat("Unexpected JSON structure in targeting response")
                }
            } catch {
                print("❌ Manual parsing also failed: \(error)")
                throw NetworkError.decodingError(error)
            }
        }
    }
    
    private func parseChannelResponse(from data: Data, originalChannel: Channel) throws -> Channel {
        print("🔍 Attempting to parse channel response for: \(originalChannel.name)")
        
        // First, let's see what the raw JSON looks like
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📄 Channel raw JSON: \(jsonString)")
        }
        
        do {
            // Try to decode as new channel structure with monthly_fees
            let decoder = JSONDecoder()
            let channelData = try decoder.decode(Channel.self, from: data)
            
            print("✅ Successfully parsed channel with new structure")
            print("📊 Found \(channelData.monthlyFees.count) monthly fee options")
            
            // Preserve the channel_id from the original channel
            
            return Channel(
                id: originalChannel.id,
                channel: originalChannel.channel,
                monthlyFees: channelData.monthlyFees,
                channelId: (try? originalChannel.getChannelId()) ?? ""
            )
        } catch {
            print("❌ Failed to parse as new channel structure: \(error)")
            
            // Try to parse as legacy campaign array and convert
            do {
                let campaignResponse = try JSONDecoder().decode(CampaignResponse.self, from: data)
                print("✅ Parsed as legacy campaign structure, converting to channel")
                
                // Convert campaigns back to monthly fees
                let monthlyFees = campaignResponse.campaigns.map { campaign in
                    MonthlyFee(
                        id: campaign.id,
                        price: campaign.monthlyFee,
                        details: campaign.detailsArray,
                        currency: campaign.currency
                    )
                }
                
                return Channel(
                    id: originalChannel.id,
                    channel: originalChannel.channel,
                    monthlyFees: monthlyFees,
                    channelId: (try? originalChannel.getChannelId()) ?? ""
                )
            } catch {
                print("❌ Failed to parse as legacy structure: \(error)")
                throw NetworkError.decodingError(error)
            }
        }
    }
    
    // MARK: - Array Parsing for Targeting Data
    
    private func parseTargetingFromArray(_ jsonArray: [Any]) throws -> TargetingResponse {
        print("🔍 Parsing targeting data from array with new structure...")
        
        var targetingSpecifics: [TargetingSpecific] = []
        var allChannels: Set<Channel> = []
        
        for (index, item) in jsonArray.enumerated() {
            print("📊 Array item \(index): \(type(of: item))")
            
            if let itemDict = item as? [String: Any] {
                print("📊 Item \(index) keys: \(itemDict.keys)")
                
                // Parse the new structure: {"target":"Location","available_channels":[...]}
                if let target = itemDict["target"] as? String,
                   let availableChannelsArray = itemDict["available_channels"] as? [[String: Any]] {
                    
                    print("✅ Found target: \(target) with \(availableChannelsArray.count) available channels")
                    
                    // Parse available channels
                    var availableChannels: [AvailableChannel] = []
                    
                    for channelDict in availableChannelsArray {
                        if let channel = channelDict["channel"] as? String,
                           let channelId = channelDict["channel_id"] as? String {
                            
                            let availableChannel = AvailableChannel(
                                id: "\(channel.lowercased().replacingOccurrences(of: " ", with: "_"))_\(channelId)",
                                channel: channel,
                                channelId: channelId
                            )
                            
                            availableChannels.append(availableChannel)
                            print("✅ Added available channel: \(channel) with ID: \(channelId)")
                        }
                    }
                    
                    // Create targeting specific
                    let targetingSpecific = TargetingSpecific(
                        id: target.lowercased().replacingOccurrences(of: " ", with: "_"),
                        target: target,
                        availableChannels: availableChannels
                    )
                    
                    targetingSpecifics.append(targetingSpecific)
                    
                    // Convert available channels to Channel objects and add to set
                    for availableChannel in availableChannels {
                        let channel = availableChannel.toChannel()
                        allChannels.insert(channel)
                    }
                }
            }
        }
        
        // If no targeting specifics found, throw error
        if targetingSpecifics.isEmpty {
            print("❌ No targeting specifics found in API response")
            throw NetworkError.invalidResponseFormat("No targeting specifics found in response")
        }
        
        print("📊 Final parsing result: \(targetingSpecifics.count) targeting specifics, \(allChannels.count) channels")
        
        return TargetingResponse(
            targetingSpecifics: targetingSpecifics,
            channels: Array(allChannels)
        )
    }
}

// MARK: - Error Types

enum NetworkError: Error {
    case networkError(AFError)
    case decodingError(Error)
    case invalidResponseFormat(String)
    case timeoutError
    
    var localizedDescription: String {
        switch self {
        case .networkError(let afError):
            return "Network error: \(afError.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .invalidResponseFormat(let message):
            return "Invalid response format: \(message)"
        case .timeoutError:
            return "Request timed out. Please try again."
        }
    }
}
