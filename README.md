# StyleMatcherAI

An iOS application that uses AI to help users create personalized outfits and manage their wardrobe efficiently.

## Features

- **AI-Powered Outfit Recommendations**: Get personalized outfit suggestions based on weather, occasion, and personal style
- **Smart Wardrobe Management**: Organize and categorize your clothing items with photo recognition
- **Style Matching**: AI-driven style analysis to suggest combinations from your existing wardrobe
- **Outfit Planning**: Plan outfits for the week ahead with calendar integration
- **Style Insights**: Track your style preferences and get insights on your fashion choices

## Architecture

This project follows the MVVM (Model-View-ViewModel) architecture pattern with a modular structure:

### Project Structure

```
StyleMatcherAI/
├── App/                    # App lifecycle and configuration
├── Core/                   # Core functionality modules
│   ├── Authentication/     # User authentication and authorization
│   ├── Database/          # Data persistence and Core Data
│   ├── Networking/        # API communication and networking
│   ├── AI/               # AI and machine learning features
│   └── Storage/          # File storage and caching
├── Features/              # Feature-specific modules
│   ├── Onboarding/       # User onboarding flow
│   ├── Wardrobe/         # Wardrobe management
│   ├── OutfitGenerator/  # AI outfit generation
│   └── Profile/          # User profile and settings
├── Models/               # Data models and entities
├── Views/                # SwiftUI views and components
│   ├── Components/       # Reusable UI components
│   └── Screens/          # Full screen views
├── ViewModels/           # Business logic and state management
├── Services/             # Shared services and utilities
└── Resources/            # Assets, configuration, and localization
    ├── Assets/           # Images, colors, and other assets
    ├── Config/           # Configuration files
    └── Localization/     # String localization files
```

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.0+

## Installation

1. Clone the repository
2. Open `StyleMatcherAI.xcodeproj` in Xcode
3. Build and run the project

## Dependencies

This project uses Swift Package Manager for dependency management. Dependencies are defined in `Package.swift`.

## Getting Started

1. Launch the app
2. Complete the onboarding process
3. Add clothing items to your wardrobe by taking photos
4. Start generating AI-powered outfit recommendations

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For questions or support, please contact the development team.