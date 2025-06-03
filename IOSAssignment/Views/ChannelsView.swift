import SwiftUI

struct ChannelsView: View {
    @StateObject private var viewModel = ChannelsViewModel()
    @EnvironmentObject private var coordinator: AppCoordinator
    
    var body: some View {
        VStack {
            // Instruction text
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("Select channels to explore their packages. You can choose one package per channel.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            List {
                ForEach(viewModel.availableChannels) { channel in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(channel.name)
                                .font(.headline)
                            
                            Text("Marketing channel")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // Show selected campaign for this channel if any
                            if let selectedCampaign = viewModel.getSelectedCampaign(for: channel) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    
                                    Text("Selected: \(selectedCampaign.name)")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    Text("(\(selectedCampaign.formattedPrice))")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                }
                                .padding(.top, 2)
                            }
                        }
                        
                        Spacer()
                        
                        VStack {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        coordinator.moveToCampaigns(for: channel)
                    }
                }
            }
            
            // Bottom action area - only show review button if campaigns are selected
            if viewModel.hasSelectedCampaigns {
                VStack(spacing: 12) {
                    Button("Review Selected Packages") {
                        coordinator.moveToReview()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canProceedToReview)
                }
                .padding()
            }
        }
        .navigationTitle("Select Channels")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.loadChannels()
        }
    }
}
