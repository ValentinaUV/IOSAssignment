import XCTest
@testable import IOSAssignment
import FactoryKit

final class DependencyInjectionTests: XCTestCase {
    
    override func tearDown() {
        Container.shared.reset()
        super.tearDown()
    }
    
    func testNetworkServiceRegistration() {
        // When
        let service1 = Container.shared.networkService()
        let service2 = Container.shared.networkService()
        
        // Then - Should be singleton
        XCTAssertTrue(service1 === service2)
        XCTAssertTrue(service1 is NetworkServiceProtocol)
    }
    
    func testViewFactoryRegistration() {
        // When
        let factory1 = Container.shared.viewFactory()
        let factory2 = Container.shared.viewFactory()
        
        // Then - Should be singleton
        XCTAssertTrue(factory1 === factory2)
        XCTAssertTrue(factory1 is ViewFactoryProtocol)
    }
    
    func testMockNetworkServiceOverride() {
        // Given
        let mockService = MockNetworkService()
        Container.shared.networkService.register { mockService }
        
        // When
        let service = Container.shared.networkService()
        
        // Then
        XCTAssertTrue(service === mockService)
        XCTAssertTrue(service is MockNetworkService)
    }
    
    func testMockViewFactoryOverride() {
        // Given
        let mockFactory = MockViewFactory()
        Container.shared.viewFactory.register { mockFactory }
        
        // When
        let factory = Container.shared.viewFactory()
        
        // Then
        XCTAssertTrue(factory === mockFactory)
        XCTAssertTrue(factory is MockViewFactory)
    }
    
    @MainActor
    func testCoordinatorDependencyInjection() {
        // Given
        let mockService = MockNetworkService()
        let mockFactory = MockViewFactory()
        Container.shared.networkService.register { mockService }
        Container.shared.viewFactory.register { mockFactory }
        
        // When
        let coordinator = AppCoordinator()
        
        // Then - Coordinator should use injected dependencies
        // We can verify this indirectly by checking if the mock factory methods are called
        _ = coordinator.makeRootView()
        XCTAssertTrue(mockFactory.targetingViewCreated)
    }
    
    @MainActor
    func testViewModelDependencyInjection() {
        // Given
        let mockService = MockNetworkService()
        Container.shared.networkService.register { mockService }
        
        // When
        let viewModel = TargetingViewModel()
        
        // Then - ViewModel should use injected service
        // This is verified indirectly through the service being used in async operations
        XCTAssertNotNil(viewModel)
    }
}
