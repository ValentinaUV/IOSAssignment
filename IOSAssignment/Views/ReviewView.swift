import SwiftUI
import MessageUI

struct ReviewView: View {
    @StateObject private var viewModel = ReviewViewModel()
    @EnvironmentObject private var coordinator: AppCoordinator
    
    @State private var showMailView = false
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
    @State private var mailError: String? = nil
    
    var body: some View {
        VStack {
            if !viewModel.hasSelectedCampaigns {
                emptyState
            } else {
                campaignsList
                
                Spacer()
                
                actionButtons
            }
        }
        .navigationTitle("Review Selection")
    }
    
    private var emptyState: some View {
        VStack {
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No packages selected")
                .font(.headline)
            Text("Go back and select some packages")
                .foregroundColor(.secondary)
        }
    }
    
    private var campaignsList: some View {
        List {
            ForEach(viewModel.selectedCampaigns) { campaign in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(campaign.name)
                                .font(.headline)
                            
                            // Show which channel this package belongs to
                            if let channelName = getChannelName(for: campaign) {
                                Text("Channel: \(channelName)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                        
                        Spacer()
                        
                        Button("Remove") {
                            viewModel.removeCampaign(campaign)
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                        .buttonStyle(.plain) // Prevents button from inheriting list row tap behavior
                    }
                    
                    Text(campaign.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(campaign.formattedPrice)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    // Display details in a more organized way with static disclosure group
                    StaticDisclosureGroup(
                        title: "Package Details"
                    ) {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(campaign.detailsArray, id: \.self) { detail in
                                HStack {
                                    Text("•")
                                        .foregroundColor(.blue)
                                    Text(detail)
                                        .font(.caption)
                                    Spacer()
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Total cost summary
            VStack(spacing: 8) {
                HStack {
                    Text("Total Monthly Cost:")
                        .font(.headline)
                    Spacer()
                    Text(viewModel.formattedTotalCost)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Text("\(viewModel.selectedCampaignCount) package(s) selected from \(viewModel.uniqueChannelCount) channel(s)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            
            Button("Send Email") {
                // IMPORTANT: Check if the device can send mail!
                if MFMailComposeViewController.canSendMail() {
                    showMailView = true
                } else {
                    mailError = "Mail services are not available on this device or no mail account is configured."
                    print(mailError!)
                }
            }
            .buttonStyle(.borderedProminent)
            
            if let error = mailError {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
            
            // Display result after mail view is dismissed
            if let result = mailResult {
                switch result {
                case .success(let composeResult):
                    switch composeResult {
                    case .cancelled:
                        Text("Email cancelled.")
                            .foregroundStyle(.red)
                    case .saved:
                        Text("Email saved as draft.")
                            .foregroundStyle(.green)
                    case .sent:
                        Text("Email sent successfully!")
                            .foregroundStyle(.green)
                    case .failed:
                        Text("Email failed to send.")
                            .foregroundStyle(.red)
                    @unknown default:
                        Text("Unknown email result.")
                            .foregroundStyle(.red)
                    }
                case .failure(let error):
                    Text("Error composing email: \(error.localizedDescription)")
                        .foregroundStyle(.red)
                }
            }
        }
        .padding()
        .sheet(isPresented: $showMailView) {
            MailView(
                result: $mailResult,
                recipients: ["bogus@bogus.com"],
                subject: "Marketing Campaign Selection - \(currentDate)",
                body: campaignsListForEmail,
                isHTML: true
            )
        }
    }
    
    private var currentDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        
        return dateFormatter.string(from: Date())
    }
    
    private var campaignsListForEmail: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        
        let currentDate = dateFormatter.string(from: Date())
        
        var html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Marketing Campaign Selection</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                    line-height: 1.6;
                    color: #333;
                    max-width: 800px;
                    margin: 0 auto;
                    padding: 20px;
                    background-color: #f8f9fa;
                }
                .container {
                    background-color: white;
                    border-radius: 12px;
                    padding: 30px;
                    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                }
                .header {
                    text-align: center;
                    margin-bottom: 30px;
                    padding-bottom: 20px;
                    border-bottom: 2px solid #007AFF;
                }
                .header h1 {
                    color: #007AFF;
                    margin: 0;
                    font-size: 28px;
                    font-weight: 600;
                }
                .header p {
                    color: #666;
                    margin: 10px 0 0 0;
                    font-size: 16px;
                }
                .summary {
                    background: linear-gradient(135deg, #007AFF 0%, #5856D6 100%);
                    color: white;
                    padding: 20px;
                    border-radius: 10px;
                    margin-bottom: 30px;
                    text-align: center;
                }
                .summary h2 {
                    margin: 0 0 10px 0;
                    font-size: 20px;
                }
                .summary .total-cost {
                    font-size: 32px;
                    font-weight: bold;
                    margin: 10px 0;
                }
                .summary .details {
                    opacity: 0.9;
                    font-size: 14px;
                }
                .campaign {
                    background-color: #f8f9fa;
                    border: 1px solid #e9ecef;
                    border-radius: 10px;
                    padding: 25px;
                    margin-bottom: 20px;
                    transition: all 0.3s ease;
                }
                .campaign:hover {
                    box-shadow: 0 4px 12px rgba(0,0,0,0.1);
                    transform: translateY(-2px);
                }
                .campaign-header {
                    display: flex;
                    justify-content: space-between;
                    align-items: flex-start;
                    margin-bottom: 15px;
                    flex-wrap: wrap;
                    gap: 10px;
                }
                .campaign-title {
                    color: #1d1d1f;
                    font-size: 22px;
                    font-weight: 600;
                    margin: 0;
                }
                .channel-badge {
                    background-color: #007AFF;
                    color: white;
                    padding: 6px 12px;
                    border-radius: 20px;
                    font-size: 12px;
                    font-weight: 500;
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                }
                .campaign-price {
                    color: #30D158;
                    font-size: 24px;
                    font-weight: bold;
                    margin: 10px 0;
                }
                .campaign-description {
                    color: #666;
                    font-size: 16px;
                    margin-bottom: 15px;
                    font-style: italic;
                }
                .features {
                    background-color: white;
                    border-radius: 8px;
                    padding: 15px;
                }
                .features h4 {
                    color: #1d1d1f;
                    margin: 0 0 12px 0;
                    font-size: 16px;
                    font-weight: 600;
                }
                .features ul {
                    margin: 0;
                    padding-left: 0;
                    list-style: none;
                }
                .features li {
                    padding: 6px 0;
                    padding-left: 25px;
                    position: relative;
                    color: #333;
                    font-size: 14px;
                }
                .features li:before {
                    content: "✓";
                    position: absolute;
                    left: 0;
                    color: #30D158;
                    font-weight: bold;
                    font-size: 16px;
                }
                .footer {
                    margin-top: 40px;
                    padding-top: 20px;
                    border-top: 1px solid #e9ecef;
                    text-align: center;
                    color: #666;
                    font-size: 14px;
                }
                .footer .timestamp {
                    background-color: #f8f9fa;
                    padding: 10px 15px;
                    border-radius: 6px;
                    display: inline-block;
                    margin-top: 10px;
                }
                @media (max-width: 600px) {
                    body {
                        padding: 10px;
                    }
                    .container {
                        padding: 20px;
                    }
                    .campaign-header {
                        flex-direction: column;
                        align-items: flex-start;
                    }
                    .summary .total-cost {
                        font-size: 24px;
                    }
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>📊 Marketing Campaign Selection</h1>
                    <p>Your selected marketing packages summary</p>
                </div>
                
                <div class="summary">
                    <h2>📈 Investment Summary</h2>
                    <div class="total-cost">\(viewModel.formattedTotalCost)</div>
                    <div class="details">
                        \(viewModel.selectedCampaignCount) package\(viewModel.selectedCampaignCount == 1 ? "" : "s") selected from \(viewModel.uniqueChannelCount) marketing channel\(viewModel.uniqueChannelCount == 1 ? "" : "s")
                    </div>
                </div>
        """
        
        // Add each campaign
        let packagesByChannel = viewModel.getPackagesByChannel()
        
        for (index, package) in packagesByChannel.enumerated() {
            let campaign = package.campaign
            let channel = package.channel
            
            html += """
            
                <div class="campaign">
                    <div class="campaign-header">
                        <h3 class="campaign-title">\(campaign.name)</h3>
                        <span class="channel-badge">\(channel.name)</span>
                    </div>
                    
                    <div class="campaign-price">\(campaign.formattedPrice)/month</div>
                    
                    <div class="campaign-description">
                        \(campaign.description)
                    </div>
                    
                    <div class="features">
                        <h4>🎯 Package Features:</h4>
                        <ul>
            """
            
            // Add campaign details as list items
            for detail in campaign.detailsArray {
                html += """
                            <li>\(detail.trimmingCharacters(in: .whitespacesAndNewlines))</li>
                """
            }
            
            html += """
                        </ul>
                    </div>
                </div>
            """
        }
        
        // Add footer
        html += """
                
                <div class="footer">
                    <p><strong>🚀 Ready to boost your marketing performance?</strong></p>
                    <p>These carefully selected packages will help you reach your target audience effectively across multiple channels.</p>
                    <div class="timestamp">
                        📅 Generated on \(currentDate)
                    </div>
                    <p style="margin-top: 20px; font-size: 12px; color: #999;">
                        This email was automatically generated by the Marketing Campaign Selection App
                    </p>
                </div>
            </div>
        </body>
        </html>
        """
        
        return html
    }
    
    private func getChannelName(for campaign: Campaign) -> String? {
        return viewModel.getChannel(for: campaign)?.name
    }
}

// Static DisclosureGroup
struct StaticDisclosureGroup<Content: View>: View {
    let title: String
    let content: Content
    @State private var isExpanded = false
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header that triggers expansion
            Button(action: {
                isExpanded.toggle()
            }) {
                HStack {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)
            
            // Static content display - no animations
            if isExpanded {
                content
            }
        }
    }
}
