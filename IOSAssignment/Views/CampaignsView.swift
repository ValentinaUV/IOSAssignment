import SwiftUI

struct CampaignsView: View {
    let channel: Channel
    @StateObject private var viewModel = CampaignsViewModel()
    @EnvironmentObject private var coordinator: AppCoordinator
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                loadingView
            } else if let errorMessage = viewModel.errorMessage {
                errorView(errorMessage)
            } else {
                campaignsList
            }
        }
        .navigationTitle(channel.name)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadChannelDetails(for: channel)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading \(channel.name) packages...")
                .font(.headline)
            
            Text("This may take a moment...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ errorMessage: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Failed to Load Channel Details")
                .font(.headline)
            
            Text(errorMessage)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Retry") {
                Task {
                    await viewModel.loadChannelDetails(for: channel)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var campaignsList: some View {
        VStack {
            if viewModel.campaigns.isEmpty {
                emptyStateView
            } else {
                VStack {
                    // Single selection instruction
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Select one package for \(channel.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    List {
                        ForEach(viewModel.campaigns) { campaign in
                            CampaignRowView(
                                campaign: campaign,
                                viewModel: viewModel
                            )
                        }
                    }
                }
            }
            
            // Show current selection and reset button
            if viewModel.hasSelectedCampaign {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Selected for \(channel.name):")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let campaignName = viewModel.selectedCampaignName {
                                Text(campaignName)
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                            
                            if let campaignPrice = viewModel.selectedCampaignPrice {
                                Text(campaignPrice)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Spacer()
                        
                        Button("Reset") {
                            viewModel.resetSelectionForChannel()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No packages available")
                .font(.headline)
            
            Text("This channel doesn't have any packages configured yet.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct CampaignRowView: View {
    let campaign: Campaign
    @ObservedObject var viewModel: CampaignsViewModel
    
    @State private var isDetailsExpanded = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(campaign.name)
                    .font(.headline)
                
                Text(campaign.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(campaign.formattedPrice)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                // Display details with expandable functionality
                VStack(alignment: .leading, spacing: 2) {
                    // Show first 3 details or all if expanded
                    let detailsToShow = isDetailsExpanded ? campaign.detailsArray : Array(campaign.detailsArray.prefix(3))
                    
                    ForEach(Array(detailsToShow.enumerated()), id: \.offset) { index, detail in
                        HStack {
                            Text("•")
                                .foregroundColor(.blue)
                            Text(detail)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    
                    // Show expand/collapse button if there are more than 3 details
                    if campaign.detailsArray.count > 3 {
                        Button(action: {
                            isDetailsExpanded.toggle()
                        }) {
                            HStack {
                                Text(isDetailsExpanded ? 
                                     "Show less" : 
                                     "... and \(campaign.detailsArray.count - 3) more"
                                )
                                .font(.caption)
                                .foregroundColor(.blue)
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                    .rotationEffect(.degrees(isDetailsExpanded ? 90 : 0))
                                
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 10)
                    }
                }
            }
            
            Spacer()
            
            // Single selection radio button style
            if viewModel.isCampaignSelected(campaign) {
                Image(systemName: "largecircle.fill.circle")
                    .foregroundColor(.blue)
                    .font(.title2)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.gray)
                    .font(.title2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            handleTap()
        }
    }
    
    private func handleTap() {
        if viewModel.isCampaignSelected(campaign) {
            // Deselect if already selected
            viewModel.deselectCampaign()
        } else {
            // Select this campaign (will automatically deselect others from same channel via AppManager)
            viewModel.selectCampaign(campaign)
        }
    }
}
