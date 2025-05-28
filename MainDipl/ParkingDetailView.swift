// Views/ParkingDetailView.swift
import SwiftUI
import SDWebImageSwiftUI

struct ParkingDetailView: View {
    let parking: Parking
    @State private var selectedLevel: Int = 1
    @State private var parkingLevel: ParkingLevel?
    @State private var isLoading = false
    @State private var error: Error?
    @State private var selectedSpot: ParkingSpot?
    @State private var showBookingView = false
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                headerView
                
                Picker("Уровень", selection: $selectedLevel) {
                    ForEach(parking.levelNumbers, id: \.self) { level in
                        Text("Уровень \(level)").tag(level)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: selectedLevel) { _ in
                    loadLevelData()
                }
                
                if let level = parkingLevel {
                    LevelMapView(level: level, selectedSpot: $selectedSpot)
                } else if isLoading {
                    ProgressView()
                } else if let error = error {
                    ErrorView(error: error, retryAction: loadLevelData)
                }
            }
            
            if let spot = selectedSpot {
                bookingButton(for: spot)
                    .transition(.move(edge: .bottom))
            }
        }
        .fullScreenCover(isPresented: $showBookingView) {
            if let spot = selectedSpot {
                BookingView(parking: parking, spot: spot, isPresented: $showBookingView)
                    .environmentObject(authManager)
            }
        }
        .onAppear {
            loadLevelData()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(parking.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(parking.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    InfoBadge(icon: "p.circle", title: "Мест", value: "\(parking.spaceCount)")
                    Spacer()
                    InfoBadge(icon: "rublesign.circle", title: "Цена", value: "\(Int(parking.price)) руб/час")
                }
                .padding(.top, 8)
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
    
    private func bookingButton(for spot: ParkingSpot) -> some View {
        VStack(spacing: 0) {
            Divider()
            Button(action: { showBookingView = true }) {
                Text("Забронировать место \(spot.spotNumber)")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
            }
            .background(Color(.systemBackground))
        }
    }
    
    private func loadLevelData() {
        guard let token = authManager.getAccessToken() else {
            error = NetworkError.unauthorized
            return
        }
        
        isLoading = true
        NetworkService.shared.fetchParkingLevel(
            parkingId: parking.id,
            levelNumber: selectedLevel,
            token: token
        ) { result in  // Убрали [weak self]
            DispatchQueue.main.async {
                self.isLoading = false  // Теперь просто self
                switch result {
                case .success(let level):
                    self.parkingLevel = level
                    self.error = nil
                case .failure(let error):
                    self.error = error
                    self.parkingLevel = nil
                }
            }
        }
    }
}

struct LevelMapView: View {
    let level: ParkingLevel
    @Binding var selectedSpot: ParkingSpot?
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                WebImage(url: URL(string: level.levelSchema))
                    .resizable()
                    .indicator(.activity)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width)
                    .background(Color(.systemGray6))
                    .overlay(
                        ForEach(level.parkingSpots) { spot in
                            ParkingSpotView(spot: spot, geometry: geometry, isSelected: selectedSpot?.id == spot.id)
                                .onTapGesture {
                                    if spot.spotStatus == .free {
                                        selectedSpot = spot
                                    }
                                }
                        }
                    )
            }
        }
    }
}

struct ParkingSpotView: View {
    let spot: ParkingSpot
    let geometry: GeometryProxy
    let isSelected: Bool
    
    var body: some View {
        let width = geometry.size.width * CGFloat(spot.width / 100)
        let height = geometry.size.height * CGFloat(spot.height / 100)
        let x = geometry.size.width * CGFloat(spot.xcoordinate / 100) - width / 2
        let y = geometry.size.height * CGFloat(spot.ycoordinate / 100) - height / 2
        
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(spot.spotStatus.color.opacity(0.3))
                .frame(width: width, height: height)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(spot.spotStatus.color, lineWidth: isSelected ? 3 : 1)
                )
            
            Image(systemName: spotIcon)
                .font(.system(size: min(width, height) * 0.5, weight: .bold))
                .foregroundColor(spot.spotStatus.color)
        }
        .position(x: x + width / 2, y: y + height / 2)
    }
    
    private var spotIcon: String {
        switch spot.spotStatus {
        case .free: return "car.fill"
        case .booked: return "clock.fill"
        case .occupied: return "xmark"
        }
    }
}

struct InfoBadge: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                Text(value)
                    .font(.system(size: 16, weight: .medium))
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct ErrorView: View {
    let error: Error
    let retryAction: () -> Void
    
    var body: some View {
        VStack {
            Text("Ошибка загрузки данных")
                .font(.headline)
            Text(error.localizedDescription)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: retryAction) {
                Text("Повторить")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}
