import XCTest
@testable import IOSAssignment
import FactoryKit

final class ViewFactoryTests: XCTestCase {
    var viewFactory: ViewFactory!
    
    override func setUp() {
        super.setUp()
        viewFactory = ViewFactory()
    }
    
    override func tearDown() {
        viewFactory = nil
        super.tearDown()
    }
    
    func testMakeTargetingView() {
        // When
        let view = viewFactory.makeTargetingView()
        
        // Then
        XCTAssertTrue(view is TargetingView)
    }
    
    func testMakeChannelsView() {
        // When
        let view = viewFactory.makeChannelsView()
        
        // Then
        XCTAssertTrue(view is ChannelsView)
    }
    
    func testMakeCampaignsView() {
        // Given
        let channel = Channel(
            id: "test",
            channel: "Test Channel",
            monthlyFees: [MonthlyFee(id: "1", price: 120.0, details: ["detail1", "detail2"], currency: "USD")]
        )
        
        // When
        let view = viewFactory.makeCampaignsView(for: channel)
        
        // Then
        XCTAssertTrue(view is CampaignsView)
        XCTAssertEqual(view.channel.id, channel.id)
        XCTAssertEqual(view.channel.name, channel.name)
    }
    
    func testMakeReviewView() {
        // When
        let view = viewFactory.makeReviewView()
        
        // Then
        XCTAssertTrue(view is ReviewView)
    }
}
