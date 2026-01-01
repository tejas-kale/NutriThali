# NutriThali

> **⚠️ IMPORTANT NOTE**: This entire codebase was written using Claude Code and Gemini CLI and has not been reviewed by me. Use at your own discretion.

An AI-powered iOS/macOS app that analyzes food images and provides comprehensive nutritional information with a specific focus on diabetic-friendly meal assessment.

![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS-lightgrey)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![iOS](https://img.shields.io/badge/iOS-26.0+-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **🤖 AI-Powered Analysis**: Leverages Google Gemini 3 Pro Preview for accurate food recognition and nutritional estimation
- **🍛 Indian Cuisine Focus**: Optimized for Indian dishes (Thali, Roti, Dal, etc.) with awareness of hidden calories from Ghee, Oil, and Butter
- **💉 Diabetic Support**: Specialized Type 2 diabetes guidance with glycemic index assessment and portion recommendations
- **📊 Visual Nutrition Data**: Interactive Charts framework visualization for macronutrients (protein, carbs, fats)
- **🎨 Color-Coded Assessment**: Easy-to-understand diabetic friendliness ratings (High/Moderate/Low)
- **📱 Cross-Platform**: Runs seamlessly on both iOS and macOS with platform-specific optimizations
- **🔒 Privacy-Focused**: API key stored locally, no data persistence, all processing via secure HTTPS
- **♿️ Accessible**: Full VoiceOver support throughout the app
- **📸 Flexible Input**: Camera capture (iOS) or file import from photo library/file system

## Screenshots

*Coming soon*

## Requirements

- **iOS**: 26.0 or later
- **macOS**: Compatible with latest macOS versions
- **Xcode**: 26.1.1 or later
- **Google Gemini API Key**: Required for food analysis ([Get one here](https://makersuite.google.com/app/apikey))

## Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/NutriThali.git
   cd NutriThali
   ```

2. **Open in Xcode**
   ```bash
   open NutriThali.xcodeproj
   ```

3. **Build and run**
   - Select your target device (iOS Simulator, macOS, or physical device)
   - Press `Cmd + R` to build and run

## Setup

### Getting a Gemini API Key

1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Create a new API key
4. Copy the API key

### Configuring the App

1. Launch NutriThali
2. When prompted, tap "Configure API Key" or navigate to Settings
3. Paste your Gemini API key
4. The app is now ready to analyze food images!

## Usage

### iOS

1. **Tap "Take Photo"** to capture a new image with your camera
   - Grant camera permission when prompted
2. **Tap "Choose from Library"** to select an existing photo
3. Wait for the AI analysis (typically 3-5 seconds)
4. Review the nutritional information, including:
   - Dish name and calories
   - Macronutrient breakdown (protein, carbs, fats)
   - General health verdict
   - Diabetic friendliness assessment
   - Specific advice for diabetic patients
   - Portion size recommendations

### macOS

1. **Click "Import Image"** to select a food image from your file system
2. Wait for the AI analysis
3. Review the comprehensive nutritional breakdown

## Architecture

NutriThali follows the **MVVM (Model-View-ViewModel)** architectural pattern:

### Structure

```
NutriThali/
├── Model/              # Data structures for API responses
│   └── FoodAnalysis.swift
├── View/               # SwiftUI user interface components
│   ├── ContentView.swift
│   ├── ResultView.swift
│   ├── CameraView.swift
│   └── SettingsView.swift
├── ViewModel/          # Business logic and state management
│   └── ScannerViewModel.swift
└── Service/            # External API integration
    └── GeminiService.swift
```

### Key Components

- **AppState Enum**: Manages the entire application flow (idle, analyzing, result, error)
- **ScannerViewModel**: `@MainActor` `ObservableObject` that coordinates image analysis
- **GeminiService**: Handles communication with Google Gemini API
- **Cross-Platform Support**: Uses conditional compilation for iOS/macOS differences

### State Management

The app uses a simple but effective state machine:

```swift
enum AppState {
    case idle           // Initial state, showing upload options
    case analyzing      // Processing image with Gemini API
    case result(FoodAnalysisResult)  // Displaying analysis results
    case error(String)  // Showing error message
}
```

## Development

### Building from Command Line

```bash
# Build the app
xcodebuild -project NutriThali.xcodeproj -scheme NutriThali -configuration Debug build

# Run unit tests
xcodebuild test -project NutriThali.xcodeproj -scheme NutriThali -destination 'platform=iOS Simulator,name=iPhone 15'

# Run UI tests
xcodebuild test -project NutriThali.xcodeproj -scheme NutriThali -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:NutriThaliUITests
```

### Adding New Features

1. Follow MVVM pattern
2. Add models in `Model/`
3. Add views in `View/`
4. Add business logic in `ViewModel/`
5. Add external services in `Service/`

### API Modifications

To modify the Gemini API prompt or response parsing:
- Edit `GeminiService.swift`
- Update the structured prompt in the `analyzeImage()` method
- Adjust `FoodAnalysisResult` model if response structure changes

## Technology Stack

- **Language**: Swift 5.0
- **UI Framework**: SwiftUI
- **Reactive Framework**: Combine
- **Charts**: SwiftUI Charts framework
- **API**: Google Gemini 3 Pro Preview
- **Concurrency**: Swift async/await
- **Data Format**: JSON for API communication

## Privacy & Security

- API key is stored locally in `UserDefaults`
- No user data is persisted on device
- No analytics or tracking
- All API communication over HTTPS
- Camera/photo library permissions requested only when needed

## Future Enhancements

- [ ] **History**: Implement CoreData to store analysis results
- [ ] **Export**: Add PDF export and system share sheet integration
- [ ] **Meal Planning**: Track daily nutritional intake across multiple meals
- [ ] **Custom Profiles**: Support different dietary profiles (keto, vegan, etc.)
- [ ] **Offline Mode**: Cache API responses for previously analyzed foods
- [ ] **Barcode Scanner**: Add nutrition label scanning capability
- [ ] **Multi-Language**: Localization for regional languages

## Known Limitations

- Requires active internet connection for analysis
- Analysis accuracy depends on image quality and Google Gemini API
- Nutritional values are estimates, not laboratory-tested measurements
- API key required (not included)
- Unused CoreData boilerplate currently present in codebase

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- **Google Gemini AI**: For providing the powerful image analysis API
- **SwiftUI Community**: For excellent documentation and examples
- **Claude Code & Gemini CLI**: AI tools used to generate this codebase

## Contact

For questions, issues, or feedback, please open an issue on GitHub.

---

**Disclaimer**: This app provides nutritional estimates for informational purposes only. Always consult with healthcare professionals for medical advice, especially regarding diabetes management.
