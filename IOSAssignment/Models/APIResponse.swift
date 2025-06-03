import Foundation

// Updated response structures for new channel format
struct ChannelResponse: Codable {
    let channels: [Channel]
    
    // Custom initializer to handle direct array response
    init(from decoder: Decoder) throws {
        // Try to decode as direct array first (new format)
        if let directArray = try? decoder.singleValueContainer().decode([Channel].self) {
            self.channels = directArray
        } else {
            // Fallback to container-based decoding (legacy format)
            let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
            
            // Look for channels under various possible keys
            let possibleKeys = ["channels", "data", "items"]
            var foundChannels: [Channel] = []
            
            for key in possibleKeys {
                if let keyValue = DynamicCodingKeys(stringValue: key),
                   let channels = try? container.decode([Channel].self, forKey: keyValue) {
                    foundChannels = channels
                    break
                }
            }
            
            self.channels = foundChannels
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(channels)
    }
    
    // Manual initializer for testing
    init(channels: [Channel]) {
        self.channels = channels
    }
}

// Updated targeting response to work with new channel structure
struct TargetingResponse: Codable {
    let targetingSpecifics: [TargetingSpecific]
    let channels: [Channel]
    
    enum CodingKeys: String, CodingKey {
        case targetingSpecifics = "targeting_specifics"
        case channels
    }
    
    // Custom initializer to handle different response formats
    init(from decoder: Decoder) throws {
        // Try to decode as direct array first (targeting specifics only)
        if let directArray = try? decoder.singleValueContainer().decode([TargetingSpecific].self) {
            self.targetingSpecifics = directArray
            
            // Extract all unique channels from targeting specifics
            var channelsSet = Set<String>()
            var allChannels: [Channel] = []
            
            for targeting in directArray {
                for availableChannel in targeting.availableChannels {
                    let channelName = availableChannel.channel
                    if !channelsSet.contains(channelName) {
                        channelsSet.insert(channelName)
                        
                        // Create channel with empty monthly fees (will be loaded separately)
                        let channel = Channel(
                            id: channelName.lowercased().replacingOccurrences(of: " ", with: "_"),
                            channel: channelName,
                            monthlyFees: [],
                            channelId: availableChannel.channelId
                        )
                        allChannels.append(channel)
                    }
                }
            }
            self.channels = allChannels
        } else {
            // Fallback to container-based decoding (legacy format)
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.targetingSpecifics = try container.decode([TargetingSpecific].self, forKey: .targetingSpecifics)
            self.channels = try container.decode([Channel].self, forKey: .channels)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(targetingSpecifics, forKey: .targetingSpecifics)
        try container.encode(channels, forKey: .channels)
    }
    
    // Manual initializer for testing and internal use
    init(targetingSpecifics: [TargetingSpecific], channels: [Channel]) {
        self.targetingSpecifics = targetingSpecifics
        self.channels = channels
    }
}

struct CampaignResponse: Codable {
    let campaigns: [Campaign]
    
    // Custom initializer to handle both direct channel response and campaign array
    init(from decoder: Decoder) throws {
        // Try to decode as Channel first (new structure)
        if let channel = try? decoder.singleValueContainer().decode(Channel.self) {
            self.campaigns = channel.toCampaigns()
        }
        // Try to decode as direct array of campaigns
        else if let directArray = try? decoder.singleValueContainer().decode([Campaign].self) {
            self.campaigns = directArray
        } else {
            // Fallback to container-based decoding
            let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
            
            // Look for campaigns under various possible keys
            let possibleKeys = ["campaigns", "data", "items"]
            var foundCampaigns: [Campaign] = []
            
            for key in possibleKeys {
                if let keyValue = DynamicCodingKeys(stringValue: key),
                   let campaigns = try? container.decode([Campaign].self, forKey: keyValue) {
                    foundCampaigns = campaigns
                    break
                }
            }
            
            self.campaigns = foundCampaigns
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(campaigns)
    }
    
    // Manual initializer for testing
    init(campaigns: [Campaign]) {
        self.campaigns = campaigns
    }
}

// Helper for dynamic coding keys
struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = String(intValue)
    }
}
