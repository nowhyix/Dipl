import SwiftUI

struct ProfileView: View {
    let parking: Parking?
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var reservationsManager: ReservationsManager
    @EnvironmentObject var mapManager: MapManager
    @State private var showHistory = false
    @State private var showArrivalConfirmation = false
    @State private var showCompleteBooking = false
    @State private var errorMessage: String?

    private let backgroundColor = Color(hex: "8DDCF7")

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(spacing: 20) {
                        if let user = authManager.currentUser {
                            userCard(user: user)
                            currentBookingSection()
                            historyCard()
                            logoutButton()
                        } else {
                            authRequiredView()
                        }
                    }
                    .padding()
                }

                if let error = errorMessage {
                    ErrorMessageView(message: error) {
                        errorMessage = nil
                    }
                    .transition(.move(edge: .top))
                }
            }
            .sheet(isPresented: $showHistory) {
                BookingHistoryView(reservations: reservationsManager.reservationsHistory)
            }
            .sheet(isPresented: $showArrivalConfirmation, onDismiss: {
                reservationsManager.loadActiveReservation()
            }) {
                if let reservation = reservationsManager.activeReservation {
                    ArrivalConfirmationView(reservation: reservation)
                }
            }
            .sheet(isPresented: $showCompleteBooking, onDismiss: {
                reservationsManager.loadActiveReservation()
            }) {
                if let reservation = reservationsManager.activeReservation,
                   let parking = mapManager.parkings.first(where: { $0.name == reservation.parkingName }) {
                    CompleteBookingView(reservation: reservation, parking: parking)
                }
            }
            .onAppear {
                if authManager.isLoggedIn {
                    reservationsManager.loadActiveReservation()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - UI Components

    private func userCard(user: User) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)

                VStack(alignment: .leading) {
                    Text(user.email)
                        .font(.title2).fontWeight(.semibold)
                    Text(user.phoneNumber)
                        .font(.subheadline).foregroundColor(.secondary)
                }
            }

            Divider()

            Text("Номер авто: \(user.registrationNumber)")
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 3)
    }

    private func currentBookingSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "parkingsign.circle.fill")
                    .foregroundColor(.blue)
                Text("Текущее бронирование")
                    .font(.headline)
            }

            Divider()

            if let reservation = reservationsManager.activeReservation {
                switch reservation.status.uppercased() {
                case "PENDING":
                    // Показываем кнопки для PENDING
                    bookingDetails(reservation)
                    HStack {
                        Button("Подтвердить прибытие") {
                            showArrivalConfirmation = true
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Отменить") {
                            cancelBooking()
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }

                case "ONGOING":
                    // Показываем кнопку завершения для ONGOING
                    bookingDetails(reservation)
                    Button("Завершить бронирование") {
                        showCompleteBooking = true
                    }
                    .buttonStyle(.borderedProminent)

                default:
                    Text("Нет активных бронирований")
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Нет активных бронирований")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 3)
    }

    private func bookingDetails(_ reservation: Reservation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            bookingInfoRow(icon: "mappin.circle", title: "Парковка", value: reservation.parkingName)
            bookingInfoRow(icon: "number.circle", title: "Место", value: reservation.spotNumber)

            if let start = reservation.parkingStart {
                bookingInfoRow(icon: "clock.fill", title: "Начато", value: formattedTime(start))
            } else {
                bookingInfoRow(icon: "clock.fill", title: "Забронировано", value: formattedTime(reservation.reservationStart))
            }
        }
    }

    private func bookingInfoRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(title)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .fontWeight(.medium)
            Spacer()
        }
    }

    private func historyCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.blue)
                Text("История бронирований")
                    .font(.headline)
            }

            Divider()

            if reservationsManager.reservationsHistory.isEmpty {
                Text("Нет истории бронирований")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Button(action: { showHistory = true }) {
                    HStack {
                        Text("Показать всю историю")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                }
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 3)
    }

    private func logoutButton() -> some View {
        Button(action: {
            let alert = UIAlertController(
                title: "Подтверждение выхода",
                message: "Вы точно хотите выйти из аккаунта?",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "Выйти", style: .destructive) { _ in
                reservationsManager.activeReservation = nil
                reservationsManager.reservationsHistory = []
                authManager.logout { result in
                    if case .failure(let error) = result {
                        errorMessage = error.localizedDescription
                    }
                }
            })

            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(alert, animated: true)
            }
        }) {
            HStack {
                Image(systemName: "arrow.backward.circle.fill")
                    .foregroundColor(.red)
                Text("Выйти")
                Spacer()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
        .foregroundColor(.red)
    }

    private func authRequiredView() -> some View {
        VStack {
            Text("Требуется авторизация")
                .foregroundColor(.secondary)

            NavigationLink(destination: LoginView()) {
                Text("Войти")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 3)
    }

    // MARK: - Logic

    private func cancelBooking() {
        reservationsManager.cancelActiveReservation { result in
            DispatchQueue.main.async {
                if case .failure(let error) = result {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Helpers

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}


struct ArrivalConfirmationView: View {
    let reservation: Reservation
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var reservationsManager: ReservationsManager

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                        .padding()
                }
            }

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Подтвердите прибытие")
                        .font(.title2)
                        .bold()

                    InfoRow(title: "Парковка:", value: reservation.parkingName)
                    InfoRow(title: "Место:", value: reservation.spotNumber)
                }
                .padding()

                Text("Нажмите кнопку ниже, чтобы подтвердить, что вы прибыли на место в течение 15 минут после бронирования.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button(action: confirmArrival) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Я на месте")
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
        .alert("Прибытие подтверждено", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Вы подтвердили прибытие на место. Хорошей парковки!")
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

    private func confirmArrival() {
        isLoading = true
        reservationsManager.confirmArrival { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success:
                    // Обновляем данные после успешного подтверждения
                    reservationsManager.loadActiveReservation()
                    showSuccess = true
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct CompleteBookingView: View {
    let reservation: Reservation
    let parking: Parking
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showConfirmation = false
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var reservationsManager: ReservationsManager

    private var timeParked: String {
        guard let start = reservation.parkingStart else { return "Нет данных" }
        let end = Date() // Текущее время как время завершения
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter.string(from: start, to: end) ?? "Нет данных"
    }
    
    private var calculatedPrice: String {
        guard let start = reservation.parkingStart else { return "Рассчитывается..." }
        let end = Date()
        let seconds = end.timeIntervalSince(start)
        let hours = max(1, Int(ceil(seconds / 3600)))
        let totalPrice = Double(hours) * parking.price
        
        return "\(Int(totalPrice)) руб"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            
            VStack(spacing: 20) {
                Text("Завершение бронирования")
                    .font(.title2)
                    .bold()
                
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(title: "Парковка:", value: reservation.parkingName)
                    InfoRow(title: "Место:", value: reservation.spotNumber)
                    InfoRow(title: "Тариф:", value: "\(Int(parking.price)) руб/час")
                    
                    if let start = reservation.parkingStart {
                        InfoRow(title: "Начато:", value: formattedTime(start))
                    }
                    
                    InfoRow(title: "Завершено:", value: formattedTime(Date()))
                    InfoRow(title: "Время парковки:", value: timeParked)
                    InfoRow(title: "Стоимость:", value: calculatedPrice)
                }
                
                Button(action: completeParking) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Подтвердить завершение")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)
            }
            .padding()
            .alert("Бронирование завершено", isPresented: $showConfirmation) {
                Button("OK") { dismiss() }
            } message: {
                Text("Спасибо за использование нашего сервиса!")
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
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func completeParking() {
        isLoading = true
        reservationsManager.completeParking { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success:
                    showConfirmation = true
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct BookingHistoryView: View {
    let reservations: [Reservation]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(reservations) { reservation in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(reservation.parkingName) - Место \(reservation.spotNumber)")
                            .font(.headline)
                        
                        if let start = reservation.parkingStart, let end = reservation.parkingEnd {
                            Text("\(formattedDate(start)) - \(formattedDate(end))")
                                .font(.subheadline)
                        }
                        
                        Text("Статус: \(reservation.status)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("История бронирований")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
