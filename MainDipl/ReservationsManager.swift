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
    
    func loadActiveReservation(completion: ((Reservation?) -> Void)? = nil) {
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
                    let active = reservations.first { $0.status.lowercased() == "active" }
                    self?.activeReservation = active
                    self?.reservationsHistory = reservations.filter { $0.status.lowercased() != "active" }
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
    
    func confirmArrival(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let reservation = activeReservation, let token = authManager.getAccessToken() else {
            completion(.failure(NetworkError.unauthorized))
            return
        }
        
        isLoading = true
        NetworkService.shared.confirmArrival(reservationId: reservation.id, token: token) { [weak self] result in
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
    
    func completeParking(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let reservation = activeReservation, let token = authManager.getAccessToken() else {
            completion(.failure(NetworkError.unauthorized))
            return
        }
        
        isLoading = true
        NetworkService.shared.completeParking(reservationId: reservation.id, token: token) { [weak self] result in
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
}
