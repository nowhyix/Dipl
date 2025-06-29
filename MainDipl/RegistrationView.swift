import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authManager: AuthManager
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var registrationNumber = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccessModal = false
    
    var body: some View {
        ZStack {
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        // Логотип
                        ZStack {
                            Image(systemName: "car.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.black)

                            ZStack {
                                Circle()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.black)

                                Text("P")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .offset(x: -20, y: -20)
                        }
                        .padding(.top, 30)
                        
                        // Заголовок
                        Text("РЕГИСТРАЦИЯ")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color.blue)
                        
                        // Поля ввода
                        VStack(spacing: 16) {
                            TextField("Телефон", text: $phoneNumber)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.phonePad)
                                .onChange(of: phoneNumber) { newValue in
                                    phoneNumber = formatPhoneNumber(newValue)
                                }
                            
                            TextField("Email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                            
                            TextField("Рег. номер", text: $registrationNumber)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.allCharacters)
                            
                            ZStack(alignment: .trailing) {
                                if isPasswordVisible {
                                    TextField("Пароль", text: $password)
                                } else {
                                    SecureField("Пароль", text: $password)
                                }
                                
                                Button(action: {
                                    isPasswordVisible.toggle()
                                }) {
                                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 8)
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(.horizontal, 20)
                        
                        // Кнопка регистрации
                        Button(action: register) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Зарегистрироваться")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 20)
                        .disabled(isLoading)
                        
                        Spacer()
                        
                        // Условия использования
                        Text("Нажимая на кнопку, вы принимаете условия пользовательского соглашения и политики конфиденциальности")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                }
                .navigationBarTitleDisplayMode(.inline)
            }
            .fullScreenCover(isPresented: $appState.showLogin) {
                LoginView()
            }
            // Плашка ошибки
            if let error = errorMessage {
                ErrorMessageView(message: error) {
                    errorMessage = nil
                }
            }
        }
        .sheet(isPresented: $showSuccessModal) {
            RegistrationSuccessModal()
                .environmentObject(appState)
        }
    }
    
    private func formatPhoneNumber(_ number: String) -> String {
        // Просто оставляем только цифры
        return number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }
    
    private func register() {
        errorMessage = nil
        isLoading = true
        
        // Валидация полей
        guard !phoneNumber.isEmpty, !email.isEmpty,
              !registrationNumber.isEmpty, !password.isEmpty else {
            errorMessage = "Пожалуйста, заполните все поля"
            isLoading = false
            return
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        guard NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email) else {
            errorMessage = "Пожалуйста, введите корректный email"
            isLoading = false
            return
        }
        
        /*let phoneRegex = "^\\+\\d \\(\\d{3}\\) \\d{3}-\\d{2}-\\d{2}$"
        guard NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: phoneNumber) else {
            errorMessage = "Введите полный номер телефона в формате +X (XXX) XXX-XX-XX"
            isLoading = false
            return
        }*/
        
        guard password.count >= 6 else {
            errorMessage = "Пароль должен содержать минимум 6 символов"
            isLoading = false
            return
        }
        
        authManager.register(
            email: email,
            password: password,
            phone: phoneNumber,
            numberPlate: registrationNumber
        ) { result in
            isLoading = false
            switch result {
            case .success:
                showSuccessModal = true
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var showLogin: Bool = false
    @Published var showRegistration: Bool = false
    
    
    init() {
        // Подписываемся на изменения AuthManager
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthChange),
            name: .authStatusChanged,
            object: nil
        )
    }
    
    @objc private func handleAuthChange(notification: Notification) {
        if let isLoggedIn = notification.object as? Bool {
            self.isLoggedIn = isLoggedIn
        }
    }
}

extension Notification.Name {
    static let authStatusChanged = Notification.Name("authStatusChanged")
}

struct RegistrationSuccessModal: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.green)
            
            Text("Регистрация завершена!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Вы успешно зарегистрировались в приложении. Теперь вы можете войти в систему.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
            
            Button(action: {
                dismiss()
                appState.showLogin = true
                appState.showRegistration = false
            }) {
                Text("Продолжить")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 20)
        }
        .padding()
        .interactiveDismissDisabled()
    }
}

struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Text(message)
                .foregroundColor(.white)
                .font(.subheadline)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .padding(.vertical, 12)
                .padding(.leading, 16)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .padding(.trailing, 12)
            }
        }
        .background(Color.red)
        .cornerRadius(8)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
}
