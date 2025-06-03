import Foundation

struct Channel: Codable, Identifiable, Hashable {
    let id: String
    let channel: String
    let monthlyFees: [MonthlyFee]
    let storedChannelId: String
    
    enum CodingKeys: String, CodingKey {
        case id, channel
        case monthlyFees = "monthly_fees"
    }
    
    // Custom initializer to handle different possible formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle channel name
        self.channel = try container.decode(String.self, forKey: .channel)
        
        // Generate ID from channel name
        self.id = channel.lowercased().replacingOccurrences(of: " ", with: "_")
        
        // Handle monthly_fees array
        self.monthlyFees = try container.decode([MonthlyFee].self, forKey: .monthlyFees)
        
        // Channel ID must be provided externally when creating from API response
        self.storedChannelId = ""
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(channel, forKey: .channel)
        try container.encode(monthlyFees, forKey: .monthlyFees)
    }
    
    // Manual initializer for testing and new structure
    init(id: String, channel: String, monthlyFees: [MonthlyFee]) {
        self.id = id
        self.channel = channel
        self.monthlyFees = monthlyFees
        self.storedChannelId = ""
    }
    
    // Initializer with channel_id for channels created from targeting data
    init(id: String, channel: String, monthlyFees: [MonthlyFee], channelId: String) {
        self.id = id
        self.channel = channel
        self.monthlyFees = monthlyFees
        self.storedChannelId = channelId
    }
    
    var name: String {
        return channel
    }
    
    func getCampaignEndpoint() throws -> String {
        guard !storedChannelId.isEmpty else {
            throw ChannelError.campaignEndpointError
        }
        return "https://api.npoint.io/\(storedChannelId)"
    }
    
    // Get the channel_id (public method for NetworkService)
    func getChannelId() throws -> String {
        guard !storedChannelId.isEmpty else {
            throw ChannelError.channelIdNotFound
        }
        return storedChannelId
    }
    
    // Convert MonthlyFees to Campaign objects
    func toCampaigns() -> [Campaign] {
        return monthlyFees.enumerated().map { index, fee in
            Campaign(
                id: "\(id)_\(index)",
                name: "\(channel) Package \(index + 1)",
                description: "Monthly package for \(channel)",
                monthlyFee: fee.price,
                details: fee.details.joined(separator: ", "),
                currency: fee.currency
            )
        }
    }
    
    // Hashable implementation using only ID to ensure uniqueness
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equatable implementation using only ID
    static func == (lhs: Channel, rhs: Channel) -> Bool {
        return lhs.id == rhs.id
    }
}

struct MonthlyFee: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let price: Double
    let details: [String]
    let currency: String
    
    enum CodingKeys: String, CodingKey {
        case price, details, currency
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle price as either double, int, or string
        if let priceDouble = try? container.decode(Double.self, forKey: .price) {
            self.price = priceDouble
        } else if let priceInt = try? container.decode(Int.self, forKey: .price) {
            self.price = Double(priceInt)
        } else if let priceString = try? container.decode(String.self, forKey: .price),
                  let priceValue = Double(priceString) {
            self.price = priceValue
        } else {
            self.price = 0.0
        }
        
        self.details = try container.decode([String].self, forKey: .details)
        self.currency = try container.decode(String.self, forKey: .currency)
        
        // Generate unique ID based on content
        self.id = "\(price)_\(currency)_\(details.count)"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(price, forKey: .price)
        try container.encode(details, forKey: .details)
        try container.encode(currency, forKey: .currency)
    }
    
    // Manual initializer for testing
    init(id: String, price: Double, details: [String], currency: String) {
        self.id = id
        self.price = price
        self.details = details
        self.currency = currency
    }
}

enum ChannelError: Error, LocalizedError {
    case channelIdNotFound
    case campaignEndpointError

    var errorDescription: String? {
        switch self {
        case .channelIdNotFound:
            return "The channel ID could not be retrieved because storedChannelId was not found."
        case .campaignEndpointError:
            return "The campaign endpoint could not be retrieved because storedChannelId was not found."
        }
    }
}
