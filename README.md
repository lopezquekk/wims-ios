# wims-ios

![Pull Request CI](https://github.com/lopezquekk/wims-ios/workflows/Pull%20Request%20CI/badge.svg)
![Main Branch CI](https://github.com/lopezquekk/wims-ios/workflows/Main%20Branch%20CI/badge.svg)
[![codecov](https://codecov.io/gh/lopezquekk/wims-ios/branch/main/graph/badge.svg)](https://codecov.io/gh/lopezquekk/wims-ios)

**Where is my stuff** - iOS application for tracking items and their physical locations using a hierarchical organization system.

## Features

- Hierarchical organization: Buildings → Rooms → Spots → Boxes → Items
- QR code scanning for quick box lookup
- SwiftUI interface with tab-based navigation
- Local persistence with SwiftData
- Modular architecture with Swift Packages

## Architecture

The project uses a modular architecture with Swift Package Manager:

- **Wims** - Main iOS app with SwiftUI views and view models
- **PersistencyLayer** - SwiftData entities, repositories, and DTOs
- **SwiftDataQuery** - Generic SwiftData query utilities

See [CLAUDE.md](CLAUDE.md) for detailed architecture documentation.

## Requirements

- iOS 17.0+
- Xcode 16.2+
- Swift 6.2

## Development

### Building

```bash
# Open Xcode project
open Wims/Wims.xcodeproj

# Build from command line
xcodebuild -project Wims/Wims.xcodeproj -scheme Wims \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### Testing

```bash
# Run all tests
xcodebuild test -project Wims/Wims.xcodeproj -scheme Wims \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Or use Fastlane
bundle exec fastlane test_app
```

### CI/CD

This project uses GitHub Actions, Fastlane, Danger, and SwiftLint for continuous integration.

See [CI.md](CI.md) for detailed CI/CD documentation.

## Contributing

1. Create a feature branch
2. Make your changes
3. Run `bundle exec fastlane pr_check` locally
4. Create a pull request using the PR template
5. Ensure CI passes and address any Danger comments

## License

[Add your license here]
