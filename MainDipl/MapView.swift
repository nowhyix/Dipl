// Views/MapView.swift
import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var mapManager: MapManager
    @State private var selectedParking: Parking?
    @State private var showParkingCard = false
    @State private var showParkingDetail = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Основная карта
            Map(
                coordinateRegion: $mapManager.region,
                annotationItems: mapManager.parkings
            ) { parking in
                MapAnnotation(coordinate: parking.coordinate) {
                    ParkingMapAnnotation(parking: parking) {
                        selectedParking = parking
                        showParkingCard = true
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            
            // Карточка парковки
            if showParkingCard, let parking = selectedParking {
                ParkingCardView(parking: parking, onClose: {
                    showParkingCard = false
                    selectedParking = nil
                }, onSelect: {
                    showParkingDetail = true
                    showParkingCard = false
                })
                .transition(.move(edge: .bottom))
                .padding()
            }
            
            // Контролы масштабирования
            VStack(spacing: 10) {
                Button(action: mapManager.zoomIn) {
                    Image(systemName: "plus")
                        .padding(10)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(5)
                        .shadow(radius: 3)
                }
                
                Button(action: mapManager.zoomOut) {
                    Image(systemName: "minus")
                        .padding(10)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(5)
                        .shadow(radius: 3)
                }
            }
            .padding(.trailing, 15)
            .padding(.bottom, 50)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .fullScreenCover(isPresented: $showParkingDetail) {
            if let parking = selectedParking {
                ParkingDetailView(parking: parking)
                    .environmentObject(mapManager.authManager)
            }
        }
        .onChange(of: selectedParking) { parking in
            if let parking = parking {
                mapManager.centerMap(on: parking.coordinate)
            }
        }
        
    }
}

struct ParkingCardView: View {
    let parking: Parking
    let onClose: () -> Void
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(parking.name)
                    .font(.headline)
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            
            Text(parking.address)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Label("\(parking.spaceCount) мест", systemImage: "parkingsign.circle")
                Spacer()
                Label("\(Int(parking.price)) руб/час", systemImage: "rublesign.circle")
            }
            .font(.caption)
            
            Button(action: onSelect) {
                Text("Выбрать место")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

struct ParkingMapAnnotation: View {
    let parking: Parking
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                Image(systemName: "p.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.blue)
                    .background(Circle().fill(Color.white))
                
                Text("\(parking.spaceCount)")
                    .font(.system(size: 10, weight: .bold))
                    .padding(4)
                    .background(Color.white)
                    .cornerRadius(4)
                    .offset(y: -5)
            }
        }
    }
}

class MapManager: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 43.1155, longitude: 131.8855),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @Published var parkings: [Parking] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    let authManager: AuthManager
    
    init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    func loadParkings() {
        guard let token = authManager.getAccessToken() else {
            error = NetworkError.unauthorized
            return
        }
        print("Access Token:", token)
        
        isLoading = true
        NetworkService.shared.fetchParkings(token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let parkings):
                    self?.parkings = parkings
                case .failure(let error):
                    self?.error = error
                }
            }
        }
    }
    
    func zoomIn() {
        withAnimation {
            region.span = MKCoordinateSpan(
                latitudeDelta: max(region.span.latitudeDelta / 2, 0.005),
                longitudeDelta: max(region.span.longitudeDelta / 2, 0.005)
            )
        }
    }
    
    func zoomOut() {
        withAnimation {
            region.span = MKCoordinateSpan(
                latitudeDelta: min(region.span.latitudeDelta * 2, 0.5),
                longitudeDelta: min(region.span.longitudeDelta * 2, 0.5)
            )
        }
    }
    
    func centerMap(on coordinate: CLLocationCoordinate2D) {
        withAnimation {
            region.center = coordinate
        }
    }
}
