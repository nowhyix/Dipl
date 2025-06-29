/*import SwiftUI

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

            if let end = reservation.parkingEnd {
                bookingInfoRow(icon: "clock.fill", title: "Завершится", value: formattedTime(end))
            } else if let start = reservation.parkingStart {
                let estimatedEnd = start.addingTimeInterval(15 * 60) // 15 минут брони
                bookingInfoRow(icon: "clock.fill", title: "Завершится", value: formattedTime(estimatedEnd))
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
    @State private var cardId: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var reservationsManager: ReservationsManager
    
    private let accentColor = Color.blue
    private let backgroundColor = Color(.systemBackground)
    
    var body: some View {
        VStack(spacing: 0) {
            // Заголовок и кнопка закрытия
            HStack {
                Text("Подтверждение прибытия")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Карточка с информацией о бронировании
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "parkingsign.circle.fill")
                                .foregroundColor(accentColor)
                            Text("Информация о бронировании")
                                .font(.headline)
                            Spacer()
                        }
                        
                        Divider()
                        
                        InfoRow(title: "Парковка:", value: reservation.parkingName)
                        InfoRow(title: "Место:", value: reservation.spotNumber)
                    }
                    .padding()
                    .background(backgroundColor)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Красивое поле для ввода ID карты
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ID карты")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                                .background(RoundedRectangle(cornerRadius: 10).fill(backgroundColor))
                            
                            HStack {
                                Image(systemName: "creditcard.fill")
                                    .foregroundColor(accentColor)
                                    .padding(.leading, 12)
                                
                                TextField("Введите номер карты", text: $cardId)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 16, weight: .medium))
                                    .padding(.vertical, 14)
                                    .padding(.trailing, 12)
                            }
                        }
                        .frame(height: 50)
                    }
                    
                    // Информационный текст
                    Text("Пожалуйста, введите ID вашей карты для подтверждения прибытия на парковочное место.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Кнопка подтверждения
                    Button(action: confirmArrival) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Подтвердить прибытие")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(accentColor)
                    .controlSize(.large)
                    .disabled(isLoading || cardId.isEmpty)
                    .padding(.top, 8)
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .alert("Прибытие подтверждено", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Ваше прибытие успешно подтверждено. Хорошей парковки!")
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
    
    private func confirmArrival() {
        guard !cardId.isEmpty else {
            errorMessage = "Пожалуйста, введите ID карты"
            return
        }
        
        isLoading = true
        reservationsManager.confirmArrival(cardId: cardId) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success:
                    reservationsManager.loadActiveReservation()
                    showSuccess = true
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// Вспомогательный вид для отображения ошибок
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

struct CompleteBookingView: View {
    let reservation: Reservation
    let parking: Parking
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showConfirmation = false
    @State private var currentTime: Date = Date()
    @State private var timer: Timer?
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var reservationsManager: ReservationsManager
    
    private let accentColor = Color.blue
    private let backgroundColor = Color(.systemBackground)
    
    // Фиксированное время начала парковки
    private var parkingStartDate: Date {
        return reservation.parkingStart ?? Date()
    }
    
    // Форматирование времени
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
    
    // Расчет продолжительности
    private var durationString: String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter.string(from: parkingStartDate, to: currentTime) ?? "0 мин"
    }
    
    // Расчет стоимости
    private var calculatedPrice: String {
        let seconds = max(60, currentTime.timeIntervalSince(parkingStartDate)) // Минимум 1 минута
        let hours = ceil(seconds / 3600) // Округляем до часов в большую сторону
        let totalPrice = hours * parking.price
        return String(format: "%.0f руб", totalPrice)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Заголовок и кнопка закрытия
            HStack {
                Text("Завершение бронирования")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Карточка с информацией о бронировании
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "parkingsign.circle.fill")
                                .foregroundColor(accentColor)
                            Text("Детали парковки")
                                .font(.headline)
                            Spacer()
                        }
                        
                        Divider()
                        
                        InfoRow(title: "Парковка:", value: reservation.parkingName)
                        InfoRow(title: "Место:", value: reservation.spotNumber)
                        InfoRow(title: "Тариф:", value: "\(Int(parking.price)) руб/час")
                    }
                    .padding()
                    .background(backgroundColor)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Карточка с временем и стоимостью
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(accentColor)
                            Text("Время парковки")
                                .font(.headline)
                            Spacer()
                        }
                        
                        Divider()
                        
                        InfoRow(title: "Начато:", value: formattedTime(parkingStartDate))
                        InfoRow(title: "Текущее время:", value: formattedTime(currentTime))
                        InfoRow(title: "Продолжительность:", value: durationString)
                        InfoRow(title: "Стоимость:", value: calculatedPrice)
                    }
                    .padding()
                    .background(backgroundColor)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Информационный текст
                    Text("Пожалуйста, подтвердите завершение бронирования. Стоимость рассчитана на основе фактического времени парковки.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Кнопка подтверждения
                    Button(action: confirmCompletion) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Подтвердить завершение")
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
        .alert("Бронирование завершено", isPresented: $showConfirmation) {
            Button("OK") { dismiss() }
        } message: {
            Text("Бронирование успешно завершено. Итоговая стоимость: \(calculatedPrice)")
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
        .onAppear {
            // Запускаем таймер для обновления отображения
            timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                currentTime = Date()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func confirmCompletion() {
        isLoading = true
        
        let seconds = currentTime.timeIntervalSince(parkingStartDate)
        let hours = ceil(seconds / 3600)
        let totalPrice = hours * parking.price
        
        reservationsManager.completeParking(
            price: totalPrice,
            endTime: currentTime,
            duration: seconds
        ) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success:
                    self.showConfirmation = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.dismiss()
                        self.reservationsManager.loadActiveReservation()
                    }
                case .failure(let error):
                    print("Ошибка завершения: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
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
*/
