import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var mapManager: MapManager
    @EnvironmentObject var reservationsManager: ReservationsManager
    
    var body: some View {
        Group {
            if isActive {
                if authManager.isLoggedIn {
                    MainTabView()
                        .environmentObject(authManager)
                        .environmentObject(mapManager)
                        .environmentObject(reservationsManager)
                } else {
                    LoginView()
                        .environmentObject(authManager)
                }
            } else {
                splashContent
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isActive = true
                }
            }
            
            // Load initial data if logged in
            if authManager.isLoggedIn {
                mapManager.loadParkings()
                reservationsManager.loadActiveReservation()
            }
        }
    }

    
    private var splashContent: some View {
        ZStack {
            RadialGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.6)]),
                         center: .center,
                         startRadius: 50,
                         endRadius: 500)
                .edgesIgnoringSafeArea(.all)

            ZStack {
                Image(systemName: "car.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.black)

                ZStack {
                    Circle()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.black)

                    Text("P")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: -30, y: -30)
            }
        }
    }
}

class MapDataManager: ObservableObject {
    @Published var isMapLoaded = false
    
    func loadMapData() {
        // Имитация загрузки данных карты
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isMapLoaded = true
        }
    }
}
