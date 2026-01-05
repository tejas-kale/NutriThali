# NutriThali Project Context

## Project Overview
**NutriThali** is a cross-platform (iOS & macOS) application built with **SwiftUI** that utilizes Google's **Gemini AI** to analyze food images. It is specifically designed to provide nutritional information with a focus on **Indian cuisine** and **diabetic-friendly** assessments (Type 2 diabetes).

*   **Frameworks:** SwiftUI, Combine, Charts, CoreData (boilerplate present but largely unused).
*   **Language:** Swift 5.0.
*   **Platforms:** iOS (26.0+), macOS.
*   **Architecture:** MVVM (Model-View-ViewModel).

## Architecture & Key Components

The project strictly follows the **MVVM** pattern.

### 1. Model (`NutriThali/Model/`)
*   **`FoodAnalysis.swift`**: Defines the data structures for the analysis result (`FoodAnalysisResult`, `MacroNutrients`) and the raw API response (`GeminiResponse`).
*   **`GeminiModel.swift`**: Enum defining the AI models used:
    *   `gemini-3-flash-preview` (Fast analysis)
    *   `gemini-3-pro-preview` (Detailed analysis)

### 2. View (`NutriThali/View/`)
*   **`ContentView.swift`**: The root view handling state transitions (idle, analyzing, result, error) and navigation.
*   **`ResultView.swift`**: Displays the analysis results, including nutritional charts, diabetic friendliness badges, and detailed advice.
*   **`CameraView.swift`**: Handles image capture (iOS specific).
*   **`SettingsView.swift`**: Manages the user's Gemini API key storage.

### 3. ViewModel (`NutriThali/ViewModel/`)
*   **`ScannerViewModel.swift`**: The core logic controller. It manages the `AppState`, handles image selection/capture, and coordinates calls to the `GeminiService`. It is `@MainActor` isolated.

### 4. Service (`NutriThali/Service/`)
*   **`GeminiService.swift`**: Handles all interactions with the Google Gemini API.
    *   **Endpoints**: Uses `https://generativelanguage.googleapis.com/v1beta/models/...:generateContent`.
    *   **Process**: Converts images to Base64 (JPEG 0.8 quality), constructs a structured prompt requesting JSON output, and parses the response.
    *   **Authentication**: Expects an API key stored in `UserDefaults` under `gemini_api_key`.

## AI Integration Details
The app sends prompts to Gemini requesting a strict **JSON** response format containing:
*   Dish Name & Portion Size
*   Calories & Macros (Protein, Carbs, Fats)
*   Diabetic Friendliness (High/Moderate/Low) & Advice
*   Health Verdict Emoji

## Building and Running

**Build:**
```bash
xcodebuild -project NutriThali.xcodeproj -scheme NutriThali -configuration Debug build
```

**Test:**
```bash
xcodebuild test -project NutriThali.xcodeproj -scheme NutriThali -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Development Conventions
*   **State Management**: Uses `AppState` enum for flow control.
*   **Concurrency**: Uses Swift structured concurrency (`async/await`, `Task`).
*   **Platform Specifics**: Uses conditional compilation (`#if os(iOS)`, `#if os(macOS)`) for platform-divergent code (e.g., `UIImage` vs `NSImage`).
*   **Persistence**: CoreData is initialized in `NutriThaliApp.swift` but currently unused for storing analysis history.

## Directory Structure
```
NutriThali/
├── NutriThaliApp.swift       # Entry point
├── Model/                    # Data models
├── View/                     # SwiftUI views
├── ViewModel/                # Logic & State
├── Service/                  # API Services
└── Assets.xcassets/          # Images & Colors
```
