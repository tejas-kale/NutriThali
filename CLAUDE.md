# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NutriThali is a SwiftUI iOS/macOS app that uses Google's Gemini AI API to analyze food images and provide nutritional information, with a specific focus on diabetic-friendly meal assessment.

**Platform:** iOS/macOS (Universal)
**Language:** Swift 5.0
**Minimum iOS Version:** 26.0 (iOS 26.1 for deployment targets)
**Xcode Version:** 26.1.1+
**Framework:** SwiftUI with Combine
**Marketing Version:** 1.0
**Build Version:** 1

## Building and Running

### Build the app
```bash
xcodebuild -project NutriThali.xcodeproj -scheme NutriThali -configuration Debug build
```

### Run unit tests
```bash
xcodebuild test -project NutriThali.xcodeproj -scheme NutriThali -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Run UI tests
```bash
xcodebuild test -project NutriThali.xcodeproj -scheme NutriThali -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:NutriThaliUITests
```

### Run a specific test
```bash
xcodebuild test -project NutriThali.xcodeproj -scheme NutriThali -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:NutriThaliTests/TestClassName/testMethodName
```

### Open in Xcode
```bash
open NutriThali.xcodeproj
```

## Architecture

### MVVM Pattern
The app follows the Model-View-ViewModel (MVVM) pattern:

- **Model** (`NutriThali/Model/`): Data structures for food analysis results
  - `FoodAnalysis.swift`: Defines `FoodAnalysisResult`, `MacroNutrients`, and `GeminiResponse` structures

- **View** (`NutriThali/View/`): SwiftUI views
  - `ContentView.swift`: Main app view with state management for idle/analyzing/result/error states, includes onboarding UI for API key setup, permission handling for camera access, file importing support, and integrated settings access
  - `ResultView.swift`: Displays nutritional analysis with interactive Charts framework visualization for macronutrients, diabetic-friendliness color-coded badges, comprehensive nutrition facts, health verdict with emoji indicators, and accessibility support
  - `CameraView.swift`: iOS-specific camera and photo library integration using `ImagePicker` with permission handling
  - `SettingsView.swift`: API key configuration interface with secure input and helpful setup instructions

- **ViewModel** (`NutriThali/ViewModel/`): Business logic and state management
  - `ScannerViewModel.swift`: Manages `AppState`, coordinates image analysis flow, handles loading states with progress tracking (`analysisProgress`), provides task cancellation support, and includes platform-specific haptic feedback (success/error notifications on iOS)

- **Service** (`NutriThali/Service/`): External API integration
  - `GeminiService.swift`: Handles Google Gemini API communication for food image analysis

### State Management

The app uses an `AppState` enum to manage the entire application flow:
```swift
enum AppState {
    case idle           // Initial state, showing upload options
    case analyzing      // Processing image with Gemini API
    case result(FoodAnalysisResult)  // Displaying analysis results
    case error(String)  // Showing error message
}
```

The `ScannerViewModel` is a `@MainActor` `ObservableObject` that:
- Maintains `@Published var appState: AppState`
- Tracks loading state with `@Published var isLoading: Bool`
- Provides analysis progress updates via `@Published var analysisProgress: String`
- Coordinates with `GeminiService` for async image analysis
- Handles error cases including missing API key with user-friendly error messages
- Supports task cancellation to prevent multiple simultaneous analyses
- Provides platform-specific haptic feedback on iOS (success and error notifications)
- Includes proper cleanup via `deinit` to cancel ongoing tasks

### Cross-Platform Support

The app uses conditional compilation for iOS/macOS differences:

- **Image Type Alias**: `PlatformImage` typealias maps to `UIImage` (iOS) or `NSImage` (macOS)
- **Image Picker**: `ImagePicker` (iOS-only) wraps `UIImagePickerController` for camera/photo library access
- **File Import**: macOS uses `fileImporter` for selecting images from the file system
- **JPEG Conversion**: Custom `NSImage` extension for macOS to convert images to JPEG data

### API Integration

**Gemini API Endpoint**: `https://generativelanguage.googleapis.com/v1beta/models/gemini-3-pro-preview:generateContent`

The `GeminiService`:
1. Retrieves API key from `UserDefaults` (key: `"gemini_api_key"`)
2. Uses `URLComponents` to safely construct API URL with query parameters
3. Trims whitespace and newlines from the API key before use
4. Converts image to base64-encoded JPEG (0.8 compression quality)
5. Sends structured prompt requesting JSON response with:
   - Dish name (handles both Indian dishes like Thali and international cuisine)
   - Calorie count (accounting for hidden calories from Ghee, Oil, Butter, Cream, Sugar)
   - Macros (protein, carbs, fats in grams)
   - General health verdict emoji (✅ or ⚠️) and brief explanation
   - Diabetic-specific assessment (High/Moderate/Low friendliness with Glycemic Index consideration)
   - Specific advice for diabetic patients (Type 2)
   - Portion size suggestions
6. Uses `generationConfig` with `response_mime_type: "application/json"` for structured output
7. Parses nested Gemini response structure and extracts JSON content
8. Decodes into `FoodAnalysisResult`

**Error Handling**: Custom `GeminiError` enum with `LocalizedError` conformance for user-facing error messages (invalidURL, noAPIKey, invalidResponse, apiError).

## Important Implementation Notes

### User Experience Enhancements
- **Onboarding**: Shows helpful setup message when API key is not configured
- **Progress Tracking**: Visual feedback during analysis with status messages ("Preparing image...", "Sending to Gemini AI...", "Processing results...")
- **Haptic Feedback** (iOS only): Success and error notifications via `UINotificationFeedbackGenerator` and `UIImpactFeedbackGenerator`
- **Smooth Transitions**: 0.3-second delay between analysis completion and results display
- **Permission Handling**: Camera permission alerts with direct link to Settings on iOS
- **Accessibility**: Full VoiceOver support with proper labels, hints, and traits throughout the app

### API Key Management
- API key is stored in `UserDefaults` with key `"gemini_api_key"`
- Key is accessed via `@AppStorage` in `SettingsView`
- The service trims whitespace/newlines from the key before use
- Missing API key triggers specific error state with user guidance

### Async/Await Pattern
- `GeminiService.analyzeImage()` is an async throwing function
- Called from `ScannerViewModel` within a `Task` block
- ViewModel is marked `@MainActor` to ensure UI updates happen on main thread
- Task cancellation is supported via `currentTask?.cancel()` to prevent multiple simultaneous analyses
- Proper cleanup in `deinit` ensures cancelled tasks don't cause issues

### Image Handling
- iOS: Uses `UIImagePickerController` wrapped in `ImagePicker` struct with support for camera and photo library
- macOS: Uses SwiftUI's `.fileImporter` with `UTType.image`
- Images are converted to JPEG with 0.8 quality before API transmission
- Custom `jpegData(compressionQuality:)` extension for `NSImage` on macOS
- Permission handling for camera access on iOS with alerts and Settings deep-linking

### Data Visualization
- Uses SwiftUI Charts framework for interactive macronutrient visualization
- Color-coded diabetic friendliness badges (Green/Orange/Red for High/Moderate/Low)
- Emoji-based health verdicts (✅ for healthy, ⚠️ for caution)
- Responsive layout adapting to different screen sizes

### Unused Code
- `Persistence.swift` contains CoreData boilerplate but is not currently used in the app
- `NutriThali.xcdatamodeld` CoreData model file is present but not utilized
- Consider removing or implementing persistent storage for analysis history if needed

## Current Project Structure

```
NutriThali/
├── NutriThaliApp.swift              # App entry point with @main
├── Persistence.swift                # Unused CoreData stack
├── Assets.xcassets/                 # App assets (icons, images, colors)
│   ├── AppIcon.appiconset/
│   ├── AppLogo.imageset/
│   └── AccentColor.colorset/
├── Model/
│   └── FoodAnalysis.swift           # Data models for API responses
├── View/
│   ├── ContentView.swift            # Main navigation and state routing
│   ├── ResultView.swift             # Results display with charts
│   ├── CameraView.swift             # iOS camera/photo picker
│   └── SettingsView.swift           # API key configuration
├── ViewModel/
│   └── ScannerViewModel.swift       # Business logic and state management
├── Service/
│   └── GeminiService.swift          # Gemini API integration
└── NutriThali.xcdatamodeld/         # Unused CoreData model
```

## Development Workflow

1. **Adding New Features**: Follow MVVM pattern - add models in `Model/`, views in `View/`, business logic in `ViewModel/`, external services in `Service/`
2. **API Changes**: Modify prompt or response parsing in `GeminiService.swift`
3. **UI Changes**: Update SwiftUI views; use `#if os(iOS)` / `#if os(macOS)` for platform-specific code
4. **Testing**: Place unit tests in `NutriThaliTests/`, UI tests in `NutriThaliUITests/`
5. **Error Handling**: Extend `GeminiError` enum for new error cases and provide user-friendly messages
6. **Accessibility**: Always add accessibility labels, hints, and traits when creating new UI components

## Key Features

- **AI-Powered Analysis**: Uses Google Gemini 3 Pro Preview for accurate food recognition and nutritional estimation
- **Indian Cuisine Focus**: Optimized prompts for Indian dishes (Thali, Roti, Dal, etc.) with awareness of hidden calories
- **Diabetic Support**: Specialized Type 2 diabetes guidance with glycemic index assessment
- **Cross-Platform**: Runs on both iOS and macOS with platform-specific optimizations
- **Privacy-Focused**: API key stored locally, no data persistence, all processing via secure HTTPS
- **Accessible**: Full VoiceOver support throughout the app
- **Modern UI**: SwiftUI with Charts framework, smooth animations, and haptic feedback

## Configuration

- **Bundle Identifier**: `com.kaletejas2006.NutriThali`
- **Development Team**: NDMG62GXZA
- **Camera Permission**: Required on iOS (`NSCameraUsageDescription` in Info.plist)
- **Photo Library Permission**: Required on iOS (`NSPhotoLibraryUsageDescription` in Info.plist)
- **Swift Concurrency**: Enabled with `SWIFT_APPROACHABLE_CONCURRENCY = YES` and `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
- **Deployment Target**: iOS 26.0, with iOS 26.1 for specific configurations

## Future Enhancement Ideas

- **History**: Implement CoreData to store analysis results for later review
- **Export**: Add ability to export results as PDF or share via system share sheet
- **Meal Planning**: Track daily nutritional intake across multiple meals
- **Custom Profiles**: Support different user profiles (diabetic, keto, vegan, etc.)
- **Offline Mode**: Cache API responses for previously analyzed foods
- **Barcode Scanner**: Add nutrition label scanning capability
- **Multi-Language**: Localization for regional languages
