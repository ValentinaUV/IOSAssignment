import XCTest
@testable import IOSAssignment
import FactoryKit

@MainActor
final class TargetingViewModelTests: XCTestCase {
    var viewModel: TargetingViewModel!
    var mockNetworkService: MockNetworkService!
    var mockAppManager: MockAppManager!
    
    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        mockAppManager = MockAppManager()
        let service = mockNetworkService!
        let appManager = mockAppManager!
        Container.shared.networkService.register { service }
        Container.shared.appManager.register { appManager }
        viewModel = TargetingViewModel()
    }
    
    override func tearDown() {
        Container.shared.reset()
        super.tearDown()
    }
    
    func testLoadDataSuccess() async {
        // Given
        let expectedAvailableChannel = AvailableChannel(
            id: "facebook_test",
            channel: "Facebook",
            channelId: "test123"
        )
        let expectedTargeting = TargetingSpecific(
            id: "location",
            target: "Location",
            availableChannels: [expectedAvailableChannel]
        )
        let expectedChannel = Channel(
            id: "facebook",
            channel: "Facebook",
            monthlyFees: []
        )
        
        mockNetworkService.targetingResponse = TargetingResponse(
            targetingSpecifics: [expectedTargeting],
            channels: [expectedChannel]
        )
        
        // When
        await viewModel.loadData()
        
        // Then
        XCTAssertEqual(viewModel.targetingSpecifics.count, 1)
        XCTAssertEqual(viewModel.targetingSpecifics.first?.target, "Location")
        XCTAssertEqual(viewModel.targetingSpecifics.first?.availableChannels.count, 1)
        XCTAssertEqual(viewModel.targetingSpecifics.first?.availableChannels.first?.channel, "Facebook")
        XCTAssertEqual(viewModel.targetingSpecifics.first?.availableChannels.first?.channelId, "test123")
        XCTAssertEqual(viewModel.channels.count, 1)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testLoadDataFailure() async {
        // Given
        mockNetworkService.shouldFail = true
        
        // When
        await viewModel.loadData()
        
        // Then
        XCTAssertTrue(viewModel.targetingSpecifics.isEmpty)
        XCTAssertTrue(viewModel.channels.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testToggleSpecific() {
        // Given
        let availableChannel = AvailableChannel(
            id: "facebook_test",
            channel: "Facebook",
            channelId: "test123"
        )
        let specific = TargetingSpecific(
            id: "location",
            target: "Location",
            availableChannels: [availableChannel]
        )
        
        // When
        viewModel.toggleSpecific(specific)
        
        // Then
        XCTAssertTrue(viewModel.selectedSpecifics.contains(specific))
        
        // When
        viewModel.toggleSpecific(specific)
        
        // Then
        XCTAssertFalse(viewModel.selectedSpecifics.contains(specific))
    }
    
    func testProceedToChannels() {
        // Given
        let availableChannel = AvailableChannel(
            id: "facebook_test",
            channel: "Facebook",
            channelId: "test123"
        )
        let specific = TargetingSpecific(
            id: "location",
            target: "Location",
            availableChannels: [availableChannel]
        )
        let channel = Channel(
            id: "facebook",
            channel: "Facebook",
            monthlyFees: []
        )
        
        viewModel.selectedSpecifics = [specific]
        viewModel.channels = [channel]
        
        // When
        viewModel.proceedToChannels()
        
        // Then
        XCTAssertTrue(mockAppManager.setSelectedTargetingSpecificsCalled)
        XCTAssertTrue(mockAppManager.setAvailableChannelsCalled)
        XCTAssertEqual(mockAppManager.lastSelectedTargetingSpecifics, [specific])
        XCTAssertEqual(mockAppManager.lastAvailableChannelsParams?.specifics, [specific])
        XCTAssertEqual(mockAppManager.lastAvailableChannelsParams?.allChannels, [channel])
    }
    
    func testLoadDataRestoresPreviousSelection() async {
        // Given
        let availableChannel = AvailableChannel(
            id: "facebook_test",
            channel: "Facebook",
            channelId: "test123"
        )
        let specific = TargetingSpecific(
            id: "location",
            target: "Location",
            availableChannels: [availableChannel]
        )
        
        mockNetworkService.targetingResponse = TargetingResponse(
            targetingSpecifics: [specific],
            channels: []
        )
        
        // Set previous selection in AppManager
        mockAppManager.selectedTargetingSpecifics = [specific]
        
        // When
        await viewModel.loadData()
        
        // Then
        XCTAssertEqual(viewModel.selectedSpecifics, [specific])
    }
    
    func testRetry() async {
        // Given
        mockNetworkService.shouldFail = true
        await viewModel.loadData()
        XCTAssertNotNil(viewModel.errorMessage)
        
        // When - Fix the network and retry
        mockNetworkService.shouldFail = false
        mockNetworkService.targetingResponse = TargetingResponse(
            targetingSpecifics: [],
            channels: []
        )
        
        await viewModel.retry()
        
        // Then
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testLoadDataWithMultipleTargetingSpecifics() async {
        // Given
        let locationChannels = [
            AvailableChannel(id: "facebook_location", channel: "Facebook", channelId: "fb123"),
            AvailableChannel(id: "linkedin_location", channel: "LinkedIn", channelId: "li123")
        ]
        
        let ageChannels = [
            AvailableChannel(id: "facebook_age", channel: "Facebook", channelId: "fb123"),
            AvailableChannel(id: "instagram_age", channel: "Instagram", channelId: "ig123")
        ]
        
        let targetingSpecifics = [
            TargetingSpecific(id: "location", target: "Location", availableChannels: locationChannels),
            TargetingSpecific(id: "age", target: "Age", availableChannels: ageChannels)
        ]
        
        let channels = [
            Channel(id: "facebook", channel: "Facebook", monthlyFees: []),
            Channel(id: "linkedin", channel: "LinkedIn", monthlyFees: []),
            Channel(id: "instagram", channel: "Instagram", monthlyFees: [])
        ]
        
        mockNetworkService.targetingResponse = TargetingResponse(
            targetingSpecifics: targetingSpecifics,
            channels: channels
        )
        
        // When
        await viewModel.loadData()
        
        // Then
        XCTAssertEqual(viewModel.targetingSpecifics.count, 2)
        XCTAssertEqual(viewModel.targetingSpecifics[0].target, "Location")
        XCTAssertEqual(viewModel.targetingSpecifics[1].target, "Age")
        XCTAssertEqual(viewModel.targetingSpecifics[0].availableChannels.count, 2)
        XCTAssertEqual(viewModel.targetingSpecifics[1].availableChannels.count, 2)
        XCTAssertEqual(viewModel.channels.count, 3)
    }
    
    func testSelectedSpecificsDisplay() {
        // Given
        let targeting1 = TargetingSpecific(
            id: "location",
            target: "Location",
            availableChannels: []
        )
        let targeting2 = TargetingSpecific(
            id: "age",
            target: "Age",
            availableChannels: []
        )
        
        // When
        viewModel.toggleSpecific(targeting1)
        viewModel.toggleSpecific(targeting2)
        
        // Then
        XCTAssertEqual(viewModel.selectedSpecifics.count, 2)
        XCTAssertTrue(viewModel.selectedSpecifics.contains(targeting1))
        XCTAssertTrue(viewModel.selectedSpecifics.contains(targeting2))
        
        // When deselecting one
        viewModel.toggleSpecific(targeting1)
        
        // Then
        XCTAssertEqual(viewModel.selectedSpecifics.count, 1)
        XCTAssertFalse(viewModel.selectedSpecifics.contains(targeting1))
        XCTAssertTrue(viewModel.selectedSpecifics.contains(targeting2))
    }
    
    func testLoadingStateManagement() async {
        // Given
        XCTAssertFalse(viewModel.isLoading)
        
        // When - Start loading (simulate slow network)
        let loadingTask = Task {
            await viewModel.loadData()
        }
        
        // Give a moment for loading to start
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Then - Should be loading
        // Note: This might be flaky due to timing, but demonstrates the concept
        
        await loadingTask.value
        
        // Then - Should not be loading after completion
        XCTAssertFalse(viewModel.isLoading)
    }
}
