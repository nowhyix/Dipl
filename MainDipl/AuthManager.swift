import Foundation
import KeychainSwift

class AuthManager: ObservableObject {
    
    @Published var isLoggedIn = false
    @Published var currentUser: User?
    
    private let keychain = KeychainSwift()
    private let baseURL = "http://localhost:20100"
    
    init() {
        checkAuthStatus()
    }
    
    private func checkAuthStatus() {
        // Проверяем наличие accessToken
        if keychain.get("accessToken") != nil {
            isLoggedIn = true
            fetchUserInfo()
        } else {
            isLoggedIn = false
            currentUser = nil
        }
    }
    
    func login(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/auth/login") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Неверный URL"])))
            return
        }
        
        let body = ["email": email, "password": password]
        let jsonData = try? JSONSerialization.data(withJSONObject: body)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Неверный ответ сервера"])))
                }
                return
            }
            
            guard let data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Нет данных от сервера"])))
                }
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let response = try JSONDecoder().decode(LoginResponse.self, from: data)
                    self.keychain.set(response.accessToken, forKey: "accessToken")
                    self.keychain.set(response.refreshToken, forKey: "refreshToken")
                    
                    DispatchQueue.main.async {
                        self.isLoggedIn = true
                        self.fetchUserInfo()
                        completion(.success(()))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Ошибка обработки ответа сервера"])))
                    }
                }
                
            case 401:
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Неверный логин или пароль"])))
                }
                
            case 500:
                if let errorResponse = try? JSONDecoder().decode(ServerErrorResponse.self, from: data) {
                    let message = errorResponse.message ?? "Ошибка сервера"
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: message])))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "Неверный логин или пароль"])))
                    }
                }
                
            default:
                if let errorResponse = try? JSONDecoder().decode(ServerErrorResponse.self, from: data) {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorResponse.message ?? "Неизвестная ошибка"])))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Ошибка сервера (код \(httpResponse.statusCode))"])))
                    }
                }
            }
        }.resume()
    }

    struct ServerErrorResponse: Codable {
        let message: String?
        let error: String?
        let statusCode: Int?
    }
    
    func register(email: String, password: String, phone: String, numberPlate: String, completion: @escaping (Result<Void, Error>) -> Void) {
            guard let url = URL(string: "\(baseURL)/api/auth/register") else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Неверный URL"])))
                return
            }
            
            let body: [String: Any] = [
                "email": email,
                "password": password,
                "phone": phone,
                "numberPlate": numberPlate
            ]


            print("Отправляемые данные регистрации:", body)
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Ошибка формирования запроса"])))
                return
            }
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("JSON данные:", jsonString)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Неверный ответ сервера"])))
                    }
                    return
                }
                
                if httpResponse.statusCode == 201 {
                    DispatchQueue.main.async {
                        completion(.success(()))
                    }
                } else {
                    let errorMessage: String
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        errorMessage = message
                    } else {
                        errorMessage = "Ошибка регистрации (код: \(httpResponse.statusCode))"
                    }
                    
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                    }
                }
            }.resume()
        }
    
    // MARK: - Logout
    func logout(completion: ((Result<Void, Error>) -> Void)? = nil) {
         guard let url = URL(string: "\(baseURL)/api/auth/logout") else {
             completion?(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Неверный URL"])))
             return
         }
         
         guard let accessToken = keychain.get("accessToken") else {
             completion?(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Токен не найден"])))
             return
         }
         
         var request = URLRequest(url: url)
         request.httpMethod = "POST"
         request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
         
         URLSession.shared.dataTask(with: request) { _, response, error in
             if let error = error {
                 DispatchQueue.main.async {
                     completion?(.failure(error))
                 }
                 return
             }
             
             DispatchQueue.main.async {
                 self.clearAuthData()
                 completion?(.success(()))
             }
         }.resume()
     }
     
     func refreshToken(completion: @escaping (Result<Void, Error>) -> Void) {
         guard let refreshToken = keychain.get("refreshToken") else {
             completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Токен не найден"])))
             return
         }
         
         guard let url = URL(string: "\(baseURL)/api/auth/refresh") else {
             completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Неверный URL"])))
             return
         }
         
         let body = ["refreshToken": refreshToken]
         let jsonData = try? JSONSerialization.data(withJSONObject: body)
         
         var request = URLRequest(url: url)
         request.httpMethod = "POST"
         request.setValue("application/json", forHTTPHeaderField: "Content-Type")
         request.httpBody = jsonData
         
         URLSession.shared.dataTask(with: request) { data, _, error in
             if let error = error {
                 DispatchQueue.main.async {
                     completion(.failure(error))
                 }
                 return
             }
             
             guard let data = data else {
                 DispatchQueue.main.async {
                     completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Нет данных"])))
                 }
                 return
             }
             
             do {
                 let response = try JSONDecoder().decode(LoginResponse.self, from: data)
                 self.keychain.set(response.accessToken, forKey: "accessToken")
                 self.keychain.set(response.refreshToken, forKey: "refreshToken")
                 
                 DispatchQueue.main.async {
                     completion(.success(()))
                 }
             } catch {
                 DispatchQueue.main.async {
                     completion(.failure(error))
                 }
             }
         }.resume()
     }
    
    // MARK: - Fetch User Info
    private func fetchUserInfo() {
        guard let url = URL(string: "\(baseURL)/api/user-info") else {
            return
        }
        
        guard let accessToken = keychain.get("accessToken") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to fetch user info: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data received for user info")
                return
            }
            
            do {
                let userInfo = try JSONDecoder().decode(UserInfoResponse.self, from: data)
                DispatchQueue.main.async {
                    self.currentUser = User(
                        id: UUID().uuidString,
                        fullName: "",
                        phoneNumber: userInfo.phone,
                        email: userInfo.email,
                        registrationNumber: userInfo.numberPlate,
                        balance: 0
                    )
                }
            } catch {
                print("Failed to decode user info: \(error)")
            }
        }.resume()
    }
    
    
    private func clearAuthData() {
        keychain.delete("accessToken")
        keychain.delete("refreshToken")
        isLoggedIn = false
        currentUser = nil
    }
    
    func getAccessToken() -> String? {
        keychain.get("accessToken")
    }
}

// MARK: - Response Models
struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String
}

struct UserInfoResponse: Codable {
    let email: String
    let phone: String
    let numberPlate: String
}
