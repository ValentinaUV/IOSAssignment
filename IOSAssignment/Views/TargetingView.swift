import SwiftUI

struct TargetingView: View {
    @StateObject private var viewModel = TargetingViewModel()
    @EnvironmentObject private var coordinator: AppCoordinator
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.targetingSpecifics.isEmpty && viewModel.errorMessage != nil {
                errorView
            } else {
                targetingContent
            }
        }
        .navigationTitle("Select Targeting")
        .task {
            await viewModel.loadData()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading targeting options...")
                .font(.headline)
            
            Text("Fetching data from server...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Failed to Load Data")
                .font(.headline)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            Text("Please check your internet connection and try again.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Retry") {
                Task {
                    await viewModel.retry()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var targetingContent: some View {
        VStack {
            targetingList
            continueButton
        }
    }
    
    private var targetingList: some View {
        List {
            ForEach(viewModel.targetingSpecifics) { specific in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(specific.target)
                            .font(.headline)
                        
                        if let description = specific.description {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("\(specific.availableChannels.count) available channels")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        // Show available channels as chips
                        if !specific.availableChannels.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 4) {
                                    ForEach(Array(specific.availableChannels.prefix(3)), id: \.id) { channel in
                                        Text(channel.channel)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                    
                                    if specific.availableChannels.count > 3 {
                                        Text("+\(specific.availableChannels.count - 3) more")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if viewModel.selectedSpecifics.contains(specific) {
                        Image(systemName: "checkmark.circle.fill")
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
                    viewModel.toggleSpecific(specific)
                }
            }
        }
    }
    
    private var continueButton: some View {
        VStack {
            if !viewModel.selectedSpecifics.isEmpty {
                Text("Selected: \(viewModel.selectedSpecifics.count) option(s)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Show selected targeting names
                HStack {
                    ForEach(Array(viewModel.selectedSpecifics.prefix(2)), id: \.id) { specific in
                        Text(specific.target)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                    }
                    
                    if viewModel.selectedSpecifics.count > 2 {
                        Text("+\(viewModel.selectedSpecifics.count - 2) more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Button("Continue") {
                viewModel.proceedToChannels()
                coordinator.moveToChannels()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.selectedSpecifics.isEmpty)
        }
        .padding()
    }
}