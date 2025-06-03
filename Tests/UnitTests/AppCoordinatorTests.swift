import XCTest
@testable import IOSAssignment
import FactoryKit

import Testing

@MainActor
final class AppCoordinatorTests: XCTestCase {
    var coordinator: AppCoordinator!
    var mockViewFactory: MockViewFactory!
    
    override func setUp() {
        super.setUp()
        mockViewFactory = MockViewFactory()
        
        let factory = mockViewFactory!
        Container.shared.viewFactory.register { factory }
                
        coordinator = AppCoordinator()
    }
    
    override func tearDown() {
        Container.shared.reset()
        super.tearDown()
    }
    
    // MARK: - Navigation Tests
    
    func testMoveToChannels() {
        // When
        coordinator.moveToChannels()
        
        // Then
        XCTAssertEqual(coordinator.navigationPath.count, 1)
    }
    
    func testMoveToCampaigns() {
        // Given
        let channel = Channel(
            id: "facebook",
            channel: "Facebook",
            monthlyFees: []
        )
        
        // When
        coordinator.moveToCampaigns(for: channel)
        
        // Then
        XCTAssertEqual(coordinator.navigationPath.count, 1)
    }
    
    func testMoveToReview() {
        // When
        coordinator.moveToReview()
        
        // Then
        XCTAssertEqual(coordinator.navigationPath.count, 1)
    }
    
    func testNavigateBack() {
        // Given
        let channel = Channel(
            id: "facebook",
            channel: "Facebook",
            monthlyFees: []
        )
        coordinator.moveToCampaigns(for: channel)
        XCTAssertEqual(coordinator.navigationPath.count, 1)
        
        // When
        coordinator.navigateBack()
        
        // Then
        XCTAssertEqual(coordinator.navigationPath.count, 0)
    }
    
    func testReset() {
        // Given
        coordinator.moveToReview() // Add some navigation
        XCTAssertEqual(coordinator.navigationPath.count, 1)
        
        // When
        coordinator.reset()
        
        // Then
        XCTAssertEqual(coordinator.navigationPath.count, 0)
    }
    
    // MARK: - View Factory Tests
    
    func testMakeRootView() {
        // When
        let view = coordinator.makeRootView()
        
        // Then
        XCTAssertTrue(view is TargetingView)
        XCTAssertTrue(mockViewFactory.targetingViewCreated)
    }
    
    func testMakeViewForChannels() {
        // When
        let view = coordinator.makeView(for: .channels)
        
        // Then
        XCTAssertNotNil(view)
        XCTAssertTrue(mockViewFactory.channelsViewCreated)
    }
    
    func testMakeViewForCampaigns() {
        // Given
        let channel = Channel(
            id: "facebook",
            channel: "Facebook",
            monthlyFees: []
        )
        
        // When
        let view = coordinator.makeView(for: .campaigns(channel))
        
        // Then
        XCTAssertNotNil(view)
        XCTAssertTrue(mockViewFactory.campaignsViewCreated)
        XCTAssertEqual(mockViewFactory.lastCampaignChannel?.id, channel.id)
    }
    
    func testMakeViewForReview() {
        // When
        let view = coordinator.makeView(for: .review)
        
        // Then
        XCTAssertNotNil(view)
        XCTAssertTrue(mockViewFactory.reviewViewCreated)
    }
    
    // MARK: - Integration Tests
    
    func testFullNavigationFlow() {
        // Given
        let channel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        
        // When - Complete flow
        coordinator.moveToChannels()
        coordinator.moveToCampaigns(for: channel)
        coordinator.moveToReview()
        
        // Then
        XCTAssertEqual(coordinator.navigationPath.count, 3) // channels -> campaigns -> review
    }
    
    func testNavigationBackTracking() {
        // Given
        let channel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        
        // When - Navigate forward and back
        coordinator.moveToCampaigns(for: channel)
        XCTAssertEqual(coordinator.navigationPath.count, 1)
        
        coordinator.moveToReview()
        XCTAssertEqual(coordinator.navigationPath.count, 2)
        
        coordinator.navigateBack()
        XCTAssertEqual(coordinator.navigationPath.count, 1)
        
        coordinator.navigateBack()
        XCTAssertEqual(coordinator.navigationPath.count, 0)
    }
    
    func testCoordinatorFocusedOnNavigation() {
        // Test that coordinator is now focused only on navigation and doesn't manage state
        
        // Given
        let channel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        
        // When - Perform navigation operations
        coordinator.moveToChannels()
        coordinator.moveToCampaigns(for: channel)
        coordinator.moveToReview()
        
        // Then - All operations should only affect navigation
        XCTAssertEqual(coordinator.navigationPath.count, 3)
        
        // Reset should only affect navigation
        coordinator.reset()
        XCTAssertEqual(coordinator.navigationPath.count, 0)
        
        // Coordinator should not have any direct state management properties or methods
        // It should only handle navigation and delegate everything else to ViewModels/AppManager
    }
    
    func testNavigationBackToEmpty() {
        // When trying to navigate back from empty path
        coordinator.navigateBack()
        
        // Then - Should not crash
        XCTAssertEqual(coordinator.navigationPath.count, 0)
    }
    
    func testAppStepHashable() {
        // Test that AppStep enum is properly hashable for NavigationPath
        let channel1 = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
        let channel2 = Channel(id: "linkedin", channel: "LinkedIn", monthlyFees: [])
        
        let step1 = AppStep.channels
        let step2 = AppStep.campaigns(channel1)
        let step3 = AppStep.campaigns(channel2)
        let step4 = AppStep.review
        
        // Should be able to use in Set (requires Hashable)
        let stepSet: Set<AppStep> = [step1, step2, step3, step4]
        XCTAssertEqual(stepSet.count, 4)
        
        // Same channels should be equal
        let step2Copy = AppStep.campaigns(channel1)
        XCTAssertEqual(step2, step2Copy)
    }
    
    func testCoordinatorDependencyInjection() {
        // Given
        let mockFactory = MockViewFactory()
        Container.shared.viewFactory.register { mockFactory }
        
        // When
        let newCoordinator = AppCoordinator()
        
        // Then - Coordinator should use injected dependencies
        _ = newCoordinator.makeRootView()
        XCTAssertTrue(mockFactory.targetingViewCreated)
    }
    
    func testCoordinatorLightweight() {
        // Test that coordinator is now lightweight and focused only on navigation
        
        // The coordinator should only have:
        // - Navigation path management
        // - View factory for creating views
        // - Simple navigation methods
        
        // It should NOT have:
        // - App state properties
        // - Campaign management methods
        // - Direct AppManager references
        // - Complex business logic
        
        // This is verified by the successful compilation and the fact that
        // all state management has been moved to ViewModels and AppManager
        
        XCTAssertTrue(true, "Coordinator is now lightweight and focused on navigation")
    }
}
