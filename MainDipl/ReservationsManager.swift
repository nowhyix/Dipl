// Managers/ReservationsManager.swift
import Foundation
import Combine
import SwiftUI

class ReservationsManager: ObservableObject {
    @Published var activeReservation: Reservation?
    @Published var reservationsHistory: [Reservation] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    let authManager: AuthManager
    
    init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    func loadActiveReservation(forceReload: Bool = false, completion: ((Reservation?) -> Void)? = nil) {
        // Если у нас уже есть активная бронь и не требуется принудительная перезагрузка, просто вернем существующие данные
        if !forceReload && activeReservation != nil {
            completion?(activeReservation)
            return
        }
        
        guard let token = authManager.getAccessToken() else {
            activeReservation = nil
            completion?(nil)
            return
        }
        
        isLoading = true
        NetworkService.shared.fetchReservations(token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let reservations):
                    let active = reservations.first {
                        let status = $0.status.lowercased()
                        return status == "active" || status == "pending" || status == "ongoing"
                    }
                    self?.activeReservation = active
                    self?.reservationsHistory = reservations.filter {
                        let status = $0.status.lowercased()
                        return status != "active" && status != "pending" && status != "ongoing"
                    }
                    completion?(active)
                case .failure(let error):
                    self?.error = error
                    completion?(nil)
                }
            }
        }
    }
    
    func cancelActiveReservation(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let reservation = activeReservation, let token = authManager.getAccessToken() else {
            completion(.failure(NetworkError.unauthorized))
            return
        }
        
        isLoading = true
        NetworkService.shared.cancelReservation(reservationId: reservation.id, token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success:
                    self?.activeReservation = nil
                    self?.loadActiveReservation()
                    completion(.success(()))
                case .failure(let error):
                    self?.error = error
                    completion(.failure(error))
                }
            }
        }
    }
    
    func confirmArrival(cardId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let reservation = activeReservation,
              let token = authManager.getAccessToken() else {
            completion(.failure(NetworkError.unauthorized))
            return
        }
        
        isLoading = true
        NetworkService.shared.confirmArrival(
            reservationId: reservation.id,
            cardId: cardId,
            token: token
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.loadActiveReservation()
                    completion(.success(()))
                case .failure(let error):
                    self?.error = error
                    completion(.failure(error))
                }
            }
        }
    }
    
    func completeParking(price: Double, endTime: Date, duration: TimeInterval, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let reservation = activeReservation,
              let token = authManager.getAccessToken() else {
            completion(.failure(NetworkError.unauthorized))
            return
        }
        
        let dateFormatter = ISO8601DateFormatter()
        let endTimeString = dateFormatter.string(from: endTime)
        
        NetworkService.shared.completeParking(
            reservationId: reservation.id,
            price: price,
            endTime: endTimeString,
            token: token, duration: duration
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.activeReservation = nil
                    self?.loadActiveReservation()
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
}
