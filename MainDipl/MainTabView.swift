import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        TabView {
            MapView() // Теперь будет работать, так как MapManager передается через environmentObject
                .tabItem {
                    Label("Главная", systemImage: "map")
                }

            FeedbackView()
                .tabItem {
                    Label("Обратная связь", systemImage: "bubble.left")
                }

            ProfileView()
                .tabItem {
                    Label("Профиль", systemImage: "person")
                }
        }
        .accentColor(.blue)
    }
}
