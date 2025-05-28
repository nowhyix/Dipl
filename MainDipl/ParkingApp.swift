import SwiftUI

@main
struct ParkingApp: App {
    @StateObject var authManager = AuthManager()
    @StateObject private var appState = AppState()
    @StateObject private var reservationsManager = ReservationsManager()
    @StateObject private var mapManager = MapManager()
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environmentObject(authManager)
                .environmentObject(appState)
                .environmentObject(reservationsManager)
                .environmentObject(mapManager)
                .preferredColorScheme(.light)
        }
    }
}

