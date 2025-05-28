import SwiftUI

@main
struct ParkingApp: App {
    @StateObject var authManager: AuthManager
    @StateObject var appState: AppState
    @StateObject var reservationsManager: ReservationsManager
    @StateObject var mapManager: MapManager
    
    init() {
        let auth = AuthManager()
        _authManager = StateObject(wrappedValue: auth)
        _appState = StateObject(wrappedValue: AppState())
        _reservationsManager = StateObject(wrappedValue: ReservationsManager(authManager: auth))
        _mapManager = StateObject(wrappedValue: MapManager(authManager: auth))
    }
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environmentObject(authManager)
                .environmentObject(appState)
                .environmentObject(reservationsManager)
                .environmentObject(mapManager)
        }
    }
}
