# Nurikabe

A Nurikabe puzzle game for iOS.

## Features

- [x] Puzzle gameplay with touch & drag
- [x] Multiple grid sizes (5x5, 10x10, 15x15)
- [x] Level selection with progress tracking
- [x] Undo/Redo support
- [x] Hint system with rewarded ads
- [x] Settings & customization
- [ ] Leaderboard
- [ ] Achievements

## Project Structure

```
Nurikabe/
├── Core/
│   ├── Ads/           # AdMob integration
│   ├── Commands/      # Undo/redo command pattern
│   ├── Config/        # Game configuration
│   ├── GameLogic/     # Solution checking, hints
│   └── Models/        # Data models
├── UI/
│   ├── Common/        # Shared UI (colors, base scene)
│   ├── Components/    # Reusable UI components
│   └── Scenes/        # Game scenes
├── Resources/         # Icons, puzzle data
└── Utils/             # Utility functions
```

## AdMob Setup

The hint feature uses Google AdMob rewarded video ads.

### Quick Setup

1. **Account**: Create an AdMob account at [admob.google.com](https://admob.google.com)
2. **Register App**: Add your iOS app and get your **App ID**
3. **Create Ad Unit**: Create a Rewarded ad unit and get your **Ad Unit ID**
4. **Configure**:
   - Update `Info.plist` → `GADApplicationIdentifier` with your App ID
   - Update `AdManager.swift` → `rewardedAdUnitID` (Release) with your Ad Unit ID

### Current Configuration

| Environment | Ad Unit ID |
|-------------|-----------|
| Debug | Google's test ID (works immediately) |
| Release | Your production ID (requires approved account) |

> **Note**: New AdMob accounts take 24-48 hours to be approved.

## Building

```bash
# Install dependencies
pod install

# Run on iOS Simulator
./run-ios.sh

# Or open in Xcode
open Nurikabe.xcworkspace
```

## Dependencies

- **Google Mobile Ads SDK** (via CocoaPods) - For rewarded video ads

## License

All rights reserved.
