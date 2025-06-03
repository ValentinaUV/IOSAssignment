import Foundation
import FactoryKit

@MainActor
class TargetingViewModel: ObservableObject {
    @Published var targetingSpecifics: [TargetingSpecific] = []
    @Published var channels: [Channel] = []
    @Published var selectedSpecifics: Set<TargetingSpecific> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkService: NetworkServiceProtocol
    private let appManager: AppManager
    
    init(
        networkService: NetworkServiceProtocol = Container.shared.networkService(),
        appManager: AppManager = Container.shared.appManager()
    ) {
        self.networkService = networkService
        self.appManager = appManager
    }
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔄 Loading targeting data from real API...")
            let response = try await networkService.fetchTargetingData()
            
            targetingSpecifics = response.targetingSpecifics
            channels = response.channels
            
            print("✅ Successfully loaded \(targetingSpecifics.count) targeting specifics and \(channels.count) channels")
            
            // Log the structure we received
            for targeting in targetingSpecifics {
                print("📊 Targeting: \(targeting.target) with \(targeting.availableChannels.count) available channels")
                for channel in targeting.availableChannels {
                    print("  - \(channel.channel) (ID: \(channel.channelId))")
                }
            }
            
            // Restore previous selection from AppManager
            selectedSpecifics = appManager.selectedTargetingSpecifics
            
        } catch {
            print("❌ Failed to load targeting data: \(error)")
            errorMessage = "Failed to load data: \(error.localizedDescription)"
            
            // Clear data on error
            targetingSpecifics = []
            channels = []
        }
        
        isLoading = false
    }
    
    func retry() async {
        await loadData()
    }
    
    func toggleSpecific(_ specific: TargetingSpecific) {
        if selectedSpecifics.contains(specific) {
            selectedSpecifics.remove(specific)
        } else {
            selectedSpecifics.insert(specific)
        }
        
        print("📝 Selected targeting specifics: \(selectedSpecifics.map { $0.target })")
    }
    
    func proceedToChannels() {
        // Update AppManager with selections
        appManager.setSelectedTargetingSpecifics(selectedSpecifics)
        appManager.setAvailableChannels(from: selectedSpecifics, allChannels: channels)
    }
}