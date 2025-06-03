import FactoryKit
import Foundation

extension Container {
    var networkService: Factory<NetworkServiceProtocol> {
        self { NetworkService.shared }
            .singleton
    }
    
    var viewFactory: Factory<ViewFactoryProtocol> {
        self { ViewFactory() }
            .singleton
    }
    
    var appManager: Factory<AppManager> {
        self { 
            // Use MainActor.assumeIsolated to create AppManager safely
            if Thread.isMainThread {
                return MainActor.assumeIsolated {
                    AppManager()
                }
            } else {
                // If not on main thread, dispatch to main thread synchronously
                return DispatchQueue.main.sync {
                    MainActor.assumeIsolated {
                        AppManager()
                    }
                }
            }
        }
        .singleton
    }
}
