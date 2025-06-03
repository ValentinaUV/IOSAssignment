import SwiftUI
import FactoryKit

struct EmailSentView: View {
    @StateObject private var viewModel = ReviewViewModel()
    @EnvironmentObject private var coordinator: AppCoordinator
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "envelope.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Email Sent!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Campaign details have been sent to bogus@bogus.com")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.selectedCampaigns) { campaign in
                    Text("• \(campaign.name)")
                        .font(.subheadline)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Button("Start Over") {
                // Reset both AppManager state and navigation
                Task { @MainActor in
                    let appManager = Container.shared.appManager()
                    appManager.reset()
                    coordinator.reset()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Success")
    }
}
