import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
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
                    Text("АВТОРИЗАЦИЯ")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color.blue)
                    
                    // Поля ввода
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
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
                    
                    // Кнопка входа
                    Button(action: login) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Войти")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 20)
                    .disabled(isLoading)
                    
                    // Ссылка на регистрацию
                    NavigationLink(destination: RegistrationView()) {
                        HStack {
                            Text("Нет аккаунта?")
                                .foregroundColor(.gray)
                            Text("Зарегистрируйтесь")
                                .foregroundColor(.blue)
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                    
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
            .overlay(errorOverlay)
        }
    }
    
    private var errorOverlay: some View {
        Group {
            if let error = errorMessage {
                ErrorMessageView(message: error) {
                    errorMessage = nil
                }
            }
        }
    }
    
    private func login() {
        // Проверка пустых полей
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Заполните поля: email и пароль!"
            return
        }
        
        // Проверка формата email
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: email) {
            errorMessage = "Введите корректный email"
            return
        }
        
        errorMessage = nil
        isLoading = true
        
        authManager.login(email: email, password: password) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success:
                    break
                case .failure(let error as NSError):
                    if error.code == 401 || error.code == 500 {
                        self.errorMessage = "Неверный логин или пароль"
                    } else {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
