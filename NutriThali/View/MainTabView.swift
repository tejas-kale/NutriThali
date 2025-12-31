import SwiftUI
import CoreData

struct MainTabView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        TabView {
            ScanView()
                .tabItem {
                    Label("Scan", systemImage: "camera.fill")
                }
                .accessibilityLabel("Scan tab")
                .accessibilityHint("Capture or select food images for analysis")

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
                .accessibilityLabel("History tab")
                .accessibilityHint("View your meal history and nutrition tracking")

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .accessibilityLabel("Settings tab")
                .accessibilityHint("Configure API key and app settings")
        }
        .accentColor(.green)
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
