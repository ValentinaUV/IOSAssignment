import SwiftUI
@testable import IOSAssignment

class MockViewFactory: ViewFactoryProtocol {
    var targetingViewCreated = false
    var channelsViewCreated = false
    var campaignsViewCreated = false
    var reviewViewCreated = false
    
    var lastCampaignChannel: Channel?
    
    func makeTargetingView() -> TargetingView {
        targetingViewCreated = true
        return TargetingView()
    }
    
    func makeChannelsView() -> ChannelsView {
        channelsViewCreated = true
        return ChannelsView()
    }
    
    func makeCampaignsView(for channel: Channel) -> CampaignsView {
        campaignsViewCreated = true
        lastCampaignChannel = channel
        return CampaignsView(channel: channel)
    }
    
    func makeReviewView() -> ReviewView {
        reviewViewCreated = true
        return ReviewView()
    }
    
    func reset() {
        targetingViewCreated = false
        channelsViewCreated = false
        campaignsViewCreated = false
        reviewViewCreated = false
        lastCampaignChannel = nil
    }
}
