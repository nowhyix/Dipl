// Views/ParkingDetailView.swift
import SwiftUI
import SDWebImageSwiftUI

struct ParkingDetailView: View {
    
    @State private var selectedLevel: Int = 1
    @State private var parkingLevel: ParkingLevel?
    @State private var isLoading = false
    @State private var error: Error?
    @State private var selectedSpot: ParkingSpot?
    @State private var showBookingView = false
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    let parking: Parking

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    headerView

                    if let level = parkingLevel {
                        LevelMapView(level: level, selectedSpot: $selectedSpot)
                            .onTapGesture {
                                // Отменяем выбор места при нажатии на свободную область
                                selectedSpot = nil
                            }
                    } else if isLoading {
                        ProgressView()
                    } else if let error = error {
                        ErrorView(error: error, retryAction: loadLevelData)
                    }
                }

                // Панель с кнопками уровней
                VStack(spacing: 10) {
                    ForEach(parking.levelNumbers, id: \.self) { level in
                        Button(action: {
                            selectedLevel = level
                            loadLevelData()
                        }) {
                            Text("\(level)")
                                .frame(width: 40, height: 40)
                                .background(selectedLevel == level ? Color.gray : Color.clear)
                                .foregroundColor(.black)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(10)
                .cornerRadius(12)
                .shadow(radius: 3)
                .position(
                    x: geometry.size.width - 20, // от правого края
                    y: geometry.size.height / 2  // по центру вертикали
                )
                
                // Кнопка бронирования снизу
                if let spot = selectedSpot {
                    VStack {
                        Spacer()
                        bookingButton(for: spot)
                    }
                    .transition(.move(edge: .bottom))
                }
            }
            .onAppear {
                loadLevelData()
            }
            .fullScreenCover(isPresented: $showBookingView) {
                if let spot = selectedSpot {
                    BookingView(parking: parking, spot: spot, isPresented: $showBookingView)
                        .environmentObject(authManager)
                        .onDisappear {
                            // Обновляем данные после закрытия окна бронирования
                            refreshLevelData()
                        }
                }
            }
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
                    InfoBadge(icon: "p.circle", title: "Мест свободно", value: "\(parking.freeSpaceCount)")
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
    
    private func refreshLevelData() {
        loadLevelData() // Просто вызываем существующий метод загрузки
    }
    
    private func bookingButton(for spot: ParkingSpot) -> some View {
        VStack(spacing: 0) {
            Divider()
            Button(action: {
                showBookingView = true
            }) {
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
            ZStack {
                // Фото как фоновое изображение
                WebImage(url: URL(string: level.levelSchema))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width)
                    .clipped()
                
                // Парковочные места поверх
                ForEach(level.parkingSpots) { spot in
                    ParkingSpotView(spot: spot, geometry: geometry, isSelected: selectedSpot?.id == spot.id)
                        .onTapGesture {
                            if spot.spotStatus == .free {
                                selectedSpot = spot
                            }
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGray6))
            .clipped()
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
        case .reserved: return "clock.fill"
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

