import SwiftUI

enum MealCategory: String, CaseIterable, Codable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snacks = "Snacks"

    var icon: String {
        switch self {
        case .breakfast:
            return "sunrise.fill"
        case .lunch:
            return "sun.max.fill"
        case .dinner:
            return "moon.stars.fill"
        case .snacks:
            return "leaf.fill"
        }
    }

    var colour: Color {
        switch self {
        case .breakfast:
            return .orange
        case .lunch:
            return .yellow
        case .dinner:
            return .indigo
        case .snacks:
            return .green
        }
    }

    var timeBasedHint: String {
        switch self {
        case .breakfast:
            return "Usually eaten between 6 AM - 10 AM"
        case .lunch:
            return "Usually eaten between 12 PM - 2 PM"
        case .dinner:
            return "Usually eaten between 7 PM - 9 PM"
        case .snacks:
            return "Light meals eaten between main meals"
        }
    }
}
