import SwiftUI
import CoreData

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.background.ignoresSafeArea()
            
            // Main Content
            TabView(selection: $selectedTab) {
                TodayView()
                    .tag(0)
                
                HistoryView()
                    .tag(1)
                
                SettingsView()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never)) // Swipeable or just switching
            .ignoresSafeArea(.keyboard, edges: .bottom)
            
            // Custom Tab Bar
            VStack {
                Spacer()
                HStack {
                    tabButton(icon: "house.fill", title: "Today", index: 0)
                    Spacer()
                    tabButton(icon: "calendar", title: "History", index: 1)
                    Spacer()
                    tabButton(icon: "gearshape.fill", title: "Settings", index: 2)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 16)
                .background(Theme.cardBackground.opacity(0.95))
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
    
    private func tabButton(icon: String, title: String, index: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .symbolVariant(selectedTab == index ? .fill : .none)
                
                Text(title)
                    .font(Theme.Typography.roundedFont(.caption2, weight: .medium))
            }
            .foregroundStyle(selectedTab == index ? Theme.primary : Color.gray)
            .frame(width: 60)
        }
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}