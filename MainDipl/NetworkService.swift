// Services/NetworkService.swift
import Foundation

enum NetworkError: Error {
    case invalidURL
    case noResponse
    case unauthorized
    case noData
    case serverError(statusCode: Int, message: String)
}

class NetworkService {
    static let shared = NetworkService()
    private let baseURL = "http://localhost:20200"
    
    private init() {}
    
    // MARK: - Parking Methods
    
    func fetchParkings(token: String, completion: @escaping (Result<[Parking], Error>) -> Void) {
        request(endpoint: "/api/parking", method: "GET", token: token, completion: completion)
    }
    
    func fetchParkingLevel(parkingId: Int, levelNumber: Int, token: String,
                          completion: @escaping (Result<ParkingLevel, Error>) -> Void) {
        request(endpoint: "/api/parking/\(parkingId)/levels/\(levelNumber)",
                method: "GET",
                token: token,
                completion: completion)
    }
    
    // MARK: - Reservation Methods
    
    func createReservation(spotId: Int, token: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let body = ["parkingSpotId": spotId]
        let bodyData = try? JSONSerialization.data(withJSONObject: body)
        
        request(endpoint: "/api/reservations",
                method: "POST",
                body: bodyData,
                token: token) { (result: Result<EmptyResponse, Error>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func fetchReservations(token: String, completion: @escaping (Result<[Reservation], Error>) -> Void) {
        request(endpoint: "/api/reservations", method: "GET", token: token, completion: completion)
    }
    
    func cancelReservation(reservationId: Int, token: String, completion: @escaping (Result<Void, Error>) -> Void) {
        request(endpoint: "/api/reservations/\(reservationId)",
                method: "DELETE",
                token: token) { (result: Result<EmptyResponse, Error>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func confirmArrival(reservationId: Int, token: String, completion: @escaping (Result<Void, Error>) -> Void) {
        request(endpoint: "/api/reservations/\(reservationId)",
                method: "PUT",
                token: token) { (result: Result<EmptyResponse, Error>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func completeParking(reservationId: Int, token: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let body = ["reservationId": reservationId]
        let bodyData = try? JSONSerialization.data(withJSONObject: body)
        
        request(endpoint: "/tech/parkingSpots",
                method: "POST",
                body: bodyData,
                token: token) { (result: Result<EmptyResponse, Error>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func request<T: Decodable>(endpoint: String, method: String, body: Data? = nil,
                                      token: String? = nil, completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.noResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if let data = data {
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        completion(.failure(NetworkError.serverError(statusCode: httpResponse.statusCode, message: errorResponse.message)))
                    } else if let errorString = String(data: data, encoding: .utf8) {
                        completion(.failure(NetworkError.serverError(statusCode: httpResponse.statusCode, message: errorString)))
                    } else {
                        completion(.failure(NetworkError.serverError(statusCode: httpResponse.statusCode, message: "Unknown error")))
                    }
                } else {
                    completion(.failure(NetworkError.serverError(statusCode: httpResponse.statusCode, message: "No error data")))
                }
                return
            }
            
            // Handle empty response for DELETE/PUT requests
            if method == "DELETE" || method == "PUT" {
                if let emptyResponse = EmptyResponse() as? T {
                    completion(.success(emptyResponse))
                }
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                    if let date = dateFormatter.date(from: dateString) {
                        return date
                    }
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
                }
                
                let decodedData = try decoder.decode(T.self, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

struct EmptyResponse: Codable {}
struct ErrorResponse: Codable {
    let message: String
}
