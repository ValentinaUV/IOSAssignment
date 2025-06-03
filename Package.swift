// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MarketingCampaignApp",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "MarketingCampaignApp",
            targets: ["MarketingCampaignApp"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        .package(url: "https://github.com/hmlongco/Factory.git", from: "2.3.0")
    ],
    targets: [
        .target(
            name: "MarketingCampaignApp",
            dependencies: [
                "Alamofire",
                .product(name: "FactoryKit", package: "Factory")
            ],
            path: "MarketingCampaignApp"
        ),
        .testTarget(
            name: "MarketingCampaignAppTests",
            dependencies: [
                "MarketingCampaignApp",
                .product(name: "FactoryKit", package: "Factory")
            ],
            path: "Tests"
        ),
    ]
)