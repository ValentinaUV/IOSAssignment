# Marketing Campaign Selection App

A SwiftUI iOS application that allows users to select marketing campaigns based on targeting specifics and channels, built with modern MVVM-C architecture and real API integration with timeout-based local file fallback. **Features clean separation of concerns: AppCoordinator handles only navigation, while ViewModels communicate directly with AppManager for state management.**

## Project Structure

```
IOSAssignment/
├── App.swift                           # Main app entry point
├── Info.plist                          # App configuration
├── Models/                             # Data models
│   ├── TargetingSpecific.swift         # Targeting options model with available_channels
│   ├── Channel.swift                   # Marketing channel model (requires channel_id from AvailableChannel)
│   ├── Campaign.swift                  # Campaign model
│   └── APIResponse.swift               # API response models
├── Services/                           # Business logic layer
│   └── NetworkService.swift            # Network service using channel_id directly from Channel objects
├── Managers/                           # State management layer
│   └── AppManager.swift                # Centralized state management for app data
├── Coordinators/                       # Navigation coordination (Navigation only)
│   └── AppCoordinator.swift            # Pure navigation coordinator (no state management)
├── ViewModels/                         # View models for MVVM (Direct AppManager communication)
│   ├── TargetingViewModel.swift        # Targeting selection logic + AppManager communication
│   ├── ChannelsViewModel.swift         # Channel selection logic + AppManager delegation
│   ├── CampaignsViewModel.swift        # Campaign selection logic + AppManager delegation
│   └── ReviewViewModel.swift           # Review logic + AppManager delegation
├── Views/                              # SwiftUI views
│   ├── ContentView.swift               # Root content view with navigation
│   ├── TargetingView.swift             # Targeting selection screen
│   ├── ChannelsView.swift              # Channel selection screen (updated UI)
│   ├── CampaignsView.swift             # Campaign selection screen (single selection)
│   ├── ReviewView.swift                # Review selections screen (enhanced)
│   └── MailView.swift                  # Email content 
├── Factories/                          # Factory pattern for dependency injection
│   └── ViewFactory.swift               # View creation factory
├── DI/                                 # Dependency injection
│   └── Container+Extensions.swift      # FactoryKit container setup
└── Specifics-JSON/                     # Local fallback files (optional)
    ├── b22fd39c053b256222b1.json       # Targeting data fallback
    ├── 0af1bfee844a7003cec5.json       # Facebook campaigns fallback
    ├── 9a464cbf5bf479321862.json       # LinkedIn campaigns fallback
    ├── 66a8bfaafccc4b2c2a9a.json       # Twitter campaigns fallback
    ├── 2ebf381815ca49157fd6.json       # Instagram campaigns fallback
    ├── 2499f739821b5ab3dcd6.json       # AdWords campaigns fallback
    └── 9789d17ffaf4432dcce0.json       # SEO campaigns fallback
```

## Architecture (Clean Separation of Concerns)

This app follows MVVM-C (Model-View-ViewModel-Coordinator) architecture with **clean separation of responsibilities**:

### Navigation Layer (AppCoordinator - Pure Navigation)
- `AppCoordinator`: **ONLY** handles navigation flow
  - Manages NavigationPath
  - Creates views through ViewFactory
  - Simple navigation methods (moveToChannels, moveToCampaigns, etc.)
  - **NO state management logic**
  - **NO AppManager dependencies**

### State Management Layer (AppManager - Centralized State)
- `AppManager`: Centralized state management for app data
  - Manages targeting specifics, available channels, and selected campaigns
  - Handles single selection constraint enforcement
  - Provides computed properties for UI (totals, validation, etc.)
  - **Complete business logic ownership**

### View Layer (ViewModels - State Communication Bridge)
- **ViewModels**: Bridge between Views and AppManager
  - `TargetingViewModel`: Network loading + AppManager communication
  - `ChannelsViewModel`: Pure AppManager delegation for channel data
  - `CampaignsViewModel`: Network loading + AppManager delegation for selection
  - `ReviewViewModel`: Pure AppManager delegation for review operations
  - **Direct AppManager communication (no Coordinator dependency)**

## Channel ID Architecture

### Strict Channel ID Requirement
All `Channel` objects **must** be created with a valid `channel_id` from `AvailableChannel` objects:

```swift
// ✅ Correct: Channel created from AvailableChannel with channel_id
let availableChannel = AvailableChannel(
    id: "facebook_location",
    channel: "Facebook", 
    channelId: "0af1bfee844a7003cec5"
)
let channel = availableChannel.toChannel()

// ❌ Error: Channel without channel_id will fail
let invalidChannel = Channel(id: "facebook", channel: "Facebook", monthlyFees: [])
// Accessing invalidChannel.getChannelId() or invalidChannel.getCampaignEndpoint() will throw error
```

## Data Flow (Clean Architecture)

```
User Interaction → SwiftUI View → ViewModel → AppManager → @Published State → SwiftUI View Update
     ↓                                                                              ↑
Navigation Request → AppCoordinator → NavigationPath → SwiftUI Navigation ←────────┘
```

### Key Benefits of Updated Architecture

#### 1. Single Responsibility Principle
```swift
// AppCoordinator: ONLY navigation
class AppCoordinator {
    func moveToChannels() { navigationPath.append(.channels) }
    func moveToReview() { navigationPath.append(.review) }
    // NO state management, NO AppManager dependency
}

// AppManager: ONLY state management
class AppManager {
    func selectCampaign(_ campaign: Campaign, for channel: Channel) { /* state logic */ }
    // NO navigation logic
}

// ViewModel: Bridge between View and AppManager
class CampaignsViewModel {
    func selectCampaign(_ campaign: Campaign, for channel: Channel) {
        appManager.selectCampaign(campaign, for: channel) // Direct delegation
    }
}
```

#### 2. Improved Testability
- **AppManager**: Testable in isolation for all business logic
- **AppCoordinator**: Testable in isolation for navigation flow
- **ViewModels**: Testable with mock AppManager (no complex coordinator mocking)

#### 3. Clear Dependencies
- **Views** → **ViewModels** → **AppManager**
- **Views** → **AppCoordinator** (navigation only)
- **No circular dependencies**
- **No Coordinator state management**

## Network Service (Direct channel_id Access)

The NetworkService uses `channel_id` directly from Channel objects with **no fallback mapping**:

#### Key Features:
1. **Direct channel_id Access**: Uses `channel.getChannelId()` method
2. **No Fallback Logic**: All channels must have valid channel_id from AvailableChannel
3. **Local File Naming**: Uses `{channel_id}.json` for local fallback files
4. **Timeout Detection**: Intelligent fallback to local files on API timeout
5. **Fail Fast Design**: Invalid channels fail immediately

#### Channel ID Flow:
```
Targeting API Response → AvailableChannel.channel_id → Channel.getChannelId() → NetworkService
                                    ↓
                         Local File: {channel_id}.json (on timeout)
```

## API Endpoints (Using channel_id)

- **Targeting & Channels**: `https://api.npoint.io/b22fd39c053b256222b1` (Returns targeting specifics with channel_ids)
- **Channel Campaigns**: `https://api.npoint.io/{channel_id}` (Uses channel_id from targeting data)
  - **Facebook**: `https://api.npoint.io/0af1bfee844a7003cec5`
  - **LinkedIn**: `https://api.npoint.io/9a464cbf5bf479321862`
  - **Twitter**: `https://api.npoint.io/66a8bfaafccc4b2c2a9a`
  - **Instagram**: `https://api.npoint.io/2ebf381815ca49157fd6`
  - **AdWords**: `https://api.npoint.io/2499f739821b5ab3dcd6`
  - **SEO**: `https://api.npoint.io/9789d17ffaf4432dcce0`

## Flow

1. **Targeting Selection**: User selects multiple targeting specifics
   - `TargetingViewModel` → loads data via NetworkService
   - `TargetingViewModel.proceedToChannels()` → updates AppManager
   - View calls `coordinator.moveToChannels()` for navigation

2. **Channel Navigation**: 
   - `ChannelsViewModel` → loads channels from AppManager
   - View calls `coordinator.moveToCampaigns(for: channel)` for navigation

3. **Package Selection**: User selects ONE package per channel
   - `CampaignsViewModel` → loads campaigns via NetworkService
   - `CampaignsViewModel.selectCampaign()` → delegates to AppManager
   - AppManager enforces single selection constraint

4. **Review**: User reviews selected packages
   - `ReviewViewModel` → accesses all data from AppManager
   - `ReviewView` → displays selected campaigns and opens a bottom sheet


## Key Features

### Clean Architecture Benefits
- **Single Responsibility**: Each class has one clear purpose
- **Dependency Inversion**: ViewModels depend on AppManager abstraction
- **Open/Closed Principle**: Easy to extend without modifying existing code
- **Interface Segregation**: Coordinator only exposes navigation methods

### Enhanced State Management
- **Centralized Control**: All app state managed by AppManager
- **Single Selection Constraint**: Enforced at manager level with clear logic
- **Real-time Validation**: Continuous validation of selection state
- **Currency Handling**: Currency totals and formatting

### Pure Navigation Architecture
- **Focused Responsibility**: AppCoordinator handles only navigation
- **No State Dependencies**: Clean separation from business logic
- **Simple API**: Easy to understand and maintain navigation flow
- **View Factory Integration**: Clean view creation and dependency injection

### Strict Channel ID Architecture
- **No Fallback Logic**: All channels must have valid channel_id
- **Data Integrity**: Ensures proper API endpoint construction
- **Fail Fast Design**: Invalid channels fail immediately
- **Clear Data Flow**: AvailableChannel → Channel → NetworkService

## Requirements

- iOS 18.0+
- Xcode 15.0+
- Swift 5.9+
- Internet connection (recommended for API data, but app works offline with local files)

## Dependencies

- **Alamofire**: For networking with robust error handling and timeout detection
- **FactoryKit**: For dependency injection and testability

## Installation and Setup

1. Clone the repository
2. Open the project in Xcode
3. Install dependencies (Alamofire and FactoryKit are included in Package.swift)
4. Build and run the project
5. Internet connection recommended but not required if local files are present
