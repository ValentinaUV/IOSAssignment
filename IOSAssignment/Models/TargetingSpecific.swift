import Foundation

struct TargetingSpecific: Codable, Identifiable, Hashable {
    let id: String
    let target: String
    let availableChannels: [AvailableChannel]
    
    enum CodingKeys: String, CodingKey {
        case target
        case availableChannels = "available_channels"
    }
    
    // Custom initializer to handle the new data structure
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.target = try container.decode(String.self, forKey: .target)
        self.availableChannels = try container.decode([AvailableChannel].self, forKey: .availableChannels)
        
        // Generate ID from target name for uniqueness
        self.id = target.lowercased().replacingOccurrences(of: " ", with: "_")
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(target, forKey: .target)
        try container.encode(availableChannels, forKey: .availableChannels)
    }
    
    // Manual initializer for testing
    init(id: String, target: String, availableChannels: [AvailableChannel]) {
        self.id = id
        self.target = target
        self.availableChannels = availableChannels
    }
    
    // Convenience computed property for backwards compatibility
    var name: String {
        return target
    }
    
    var description: String? {
        return "Target based on \(target.lowercased())"
    }
    
    // Hashable implementation using only ID to ensure uniqueness
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equatable implementation using only ID
    static func == (lhs: TargetingSpecific, rhs: TargetingSpecific) -> Bool {
        return lhs.id == rhs.id
    }
}

struct AvailableChannel: Codable, Identifiable, Hashable {
    let id: String
    let channel: String
    let channelId: String
    
    enum CodingKeys: String, CodingKey {
        case channel
        case channelId = "channel_id"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.channel = try container.decode(String.self, forKey: .channel)
        self.channelId = try container.decode(String.self, forKey: .channelId)
        
        // Create unique ID from channel name and channel_id
        self.id = "\(channel.lowercased().replacingOccurrences(of: " ", with: "_"))_\(channelId)"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(channel, forKey: .channel)
        try container.encode(channelId, forKey: .channelId)
    }
    
    // Manual initializer for testing
    init(id: String, channel: String, channelId: String) {
        self.id = id
        self.channel = channel
        self.channelId = channelId
    }
    
    // Convert to Channel model (updated to include channel_id)
    func toChannel() -> Channel {
        return Channel(
            id: channel.lowercased().replacingOccurrences(of: " ", with: "_"),
            channel: channel,
            monthlyFees: [], // Will be populated when loading channel details
            channelId: channelId // Pass the channel_id from targeting data
        )
    }
    
    // Hashable implementation using only ID to ensure uniqueness
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equatable implementation using only ID
    static func == (lhs: AvailableChannel, rhs: AvailableChannel) -> Bool {
        return lhs.id == rhs.id
    }
}