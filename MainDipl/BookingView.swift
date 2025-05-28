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

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                        .padding()
                }
            }

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Бронирование места")
                        .font(.title2)
                        .bold()

                    InfoRow(title: "Парковка:", value: parking.name)
                    InfoRow(title: "Адрес:", value: parking.address)
                    InfoRow(title: "Место:", value: spot.spotNumber)
                    InfoRow(title: "Цена:", value: "\(Int(parking.price)) руб/час")
                }
                .padding()

                Text("У вас есть 15 минут, чтобы прибыть на место. После этого бронь будет автоматически отменена.")
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button(action: bookSpot) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Забронировать")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 8)
            )
            .padding()
        }
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
                    ErrorMessageView(message: error) {
                        errorMessage = nil
                    }
                    .transition(.move(edge: .top))
                }
            }
        )
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

struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
                .multilineTextAlignment(.trailing)
        }
    }
}
