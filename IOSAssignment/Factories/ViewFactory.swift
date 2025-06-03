import SwiftUI
import FactoryKit

protocol ViewFactoryProtocol: AnyObject {
    func makeTargetingView() -> TargetingView
    func makeChannelsView() -> ChannelsView
    func makeCampaignsView(for channel: Channel) -> CampaignsView
    func makeReviewView() -> ReviewView
}

class ViewFactory: ViewFactoryProtocol {
    
    func makeTargetingView() -> TargetingView {
        TargetingView()
    }
    
    func makeChannelsView() -> ChannelsView {
        ChannelsView()
    }
    
    func makeCampaignsView(for channel: Channel) -> CampaignsView {
        CampaignsView(channel: channel)
    }
    
    func makeReviewView() -> ReviewView {
        ReviewView()
    }
}
