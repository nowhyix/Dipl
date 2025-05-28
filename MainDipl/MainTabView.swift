import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        TabView {
            MapView()
                .tabItem {
                    Label("Главная", systemImage: "map")
                }

            FeedbackView()
                .tabItem {
                    Label("Обратная связь", systemImage: "bubble.left")
                }

            ProfileView(parking: nil)  // Передаем nil
                .tabItem {
                    Label("Профиль", systemImage: "person")
                }
        }
    }
}
