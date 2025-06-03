import Foundation

struct Campaign: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let monthlyFee: Double
    let details: String
    let currency: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, details, currency
        case monthlyFee = "monthly_fee"
    }
    
    // Custom initializer to handle different possible formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle id as either string or int, with fallback to UUID
        if let idString = try? container.decode(String.self, forKey: .id) {
            self.id = idString
        } else if let idInt = try? container.decode(Int.self, forKey: .id) {
            self.id = String(idInt)
        } else {
            // Generate unique ID if not present
            self.id = UUID().uuidString
        }
        
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        self.details = try container.decode(String.self, forKey: .details)
        
        // Handle currency with default
        self.currency = try container.decodeIfPresent(String.self, forKey: .currency) ?? "USD"
        
        // Handle monthly_fee as either double, int, or string
        if let feeDouble = try? container.decode(Double.self, forKey: .monthlyFee) {
            self.monthlyFee = feeDouble
        } else if let feeInt = try? container.decode(Int.self, forKey: .monthlyFee) {
            self.monthlyFee = Double(feeInt)
        } else if let feeString = try? container.decode(String.self, forKey: .monthlyFee),
                  let feeValue = Double(feeString) {
            self.monthlyFee = feeValue
        } else {
            self.monthlyFee = 0.0
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(monthlyFee, forKey: .monthlyFee)
        try container.encode(details, forKey: .details)
        try container.encode(currency, forKey: .currency)
    }
    
    // Manual initializer for new structure
    init(id: String, name: String, description: String, monthlyFee: Double, details: String, currency: String = "USD") {
        self.id = id
        self.name = name
        self.description = description
        self.monthlyFee = monthlyFee
        self.details = details
        self.currency = currency
    }
    
    // Formatted price string
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: monthlyFee)) ?? "\(currency) \(monthlyFee)"
    }
    
    // Details as array for easier display
    var detailsArray: [String] {
        return details.components(separatedBy: ", ")
    }
    
    // Hashable implementation using only ID to ensure uniqueness
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equatable implementation using only ID
    static func == (lhs: Campaign, rhs: Campaign) -> Bool {
        return lhs.id == rhs.id
    }
}