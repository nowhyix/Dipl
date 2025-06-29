// Views/BookingView.swift
import SwiftUI

struct BookingView: View {
    let parking: Parking
    let spot: ParkingSpot
    @Binding var isPresented: Bool
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var reservationsManager: ReservationsManager
    @EnvironmentObject var mapManager: MapManager
    
    private let accentColor = Color.blue
    private let backgroundColor = Color(.systemBackground)
    private let warningColor = Color.orange

    var body: some View {
        VStack(spacing: 0) {
            // Заголовок и кнопка закрытия
            HStack {
                Text("Бронирование места")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Карточка с информацией о парковке
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "parkingsign.circle.fill")
                                .foregroundColor(accentColor)
                            Text("Информация о парковке")
                                .font(.headline)
                            Spacer()
                        }
                        
                        Divider()
                        
                        InfoRow(title: "Парковка:", value: parking.name)
                        InfoRow(title: "Адрес:", value: parking.address)
                        InfoRow(title: "Место:", value: spot.spotNumber)
                        InfoRow(title: "Тариф:", value: "\(Int(parking.price)) руб/час")
                    }
                    .padding()
                    .background(backgroundColor)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Предупреждение о времени
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(warningColor)
                            Text("Важно!")
                                .font(.headline)
                                .foregroundColor(warningColor)
                            Spacer()
                        }
                        
                        Text("У вас есть 15 минут, чтобы прибыть на место. После этого бронь будет автоматически отменена.")
                            .font(.subheadline)
                            .foregroundColor(warningColor)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .background(warningColor.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(warningColor, lineWidth: 1)
                    )
                    
                    // Кнопка бронирования
                    Button(action: bookSpot) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Забронировать место")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(accentColor)
                    .controlSize(.large)
                    .disabled(isLoading)
                    .padding(.top, 8)
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .alert("Бронирование подтверждено", isPresented: $showSuccess) {
            Button("OK") {
                isPresented = false
                reservationsManager.loadActiveReservation()
                mapManager.loadParkings()
            }
        } message: {
            Text("Место \(spot.spotNumber) забронировано. Подъедьте к месту в течение 15 минут.")
        }
        .overlay(
            Group {
                if let error = errorMessage {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            errorMessage = nil
                        }
                    
                    ErrorCardView(message: error) {
                        errorMessage = nil
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        )
        .animation(.default, value: errorMessage)
    }

    private func bookSpot() {
        guard let token = authManager.getAccessToken() else {
            errorMessage = "Требуется авторизация"
            return
        }
        
        isLoading = true
        errorMessage = nil

        NetworkService.shared.createReservation(spotId: spot.id, token: token) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success:
                    showSuccess = true
                    // Запускаем таймер на 15 минут
                    DispatchQueue.main.asyncAfter(deadline: .now() + 15 * 60) {
                        checkConfirmation()
                    }
                case .failure(let error):
                    handleBookingError(error)
                }
            }
        }
    }
    
    struct ErrorCardView: View {
        let message: String
        let onDismiss: () -> Void
        
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
                
                Text(message)
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                
                Button("OK", action: onDismiss)
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
            }
            .padding()
            .frame(maxWidth: 280)
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(radius: 10)
        }
    }

    private func checkConfirmation() {
        reservationsManager.loadActiveReservation { reservation in
            if let reservation = reservation, reservation.parkingStart == nil {
                // Если не подтверждено - отменяем
                cancelReservation(reservationId: reservation.id)
            }
        }
    }
    
    private func cancelReservation(reservationId: Int) {
        guard let token = authManager.getAccessToken() else { return }
        
        NetworkService.shared.cancelReservation(reservationId: reservationId, token: token) { _ in
            reservationsManager.loadActiveReservation()
        }
    }
    
    private func handleBookingError(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized:
                errorMessage = "Требуется авторизация"
            case .serverError(let statusCode, let message):
                errorMessage = "Ошибка сервера (\(statusCode)): \(message)"
            default:
                errorMessage = "Ошибка при бронировании"
            }
        } else {
            errorMessage = error.localizedDescription
        }
    }
}

// Обновленный InfoRow для единого стиля
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}

