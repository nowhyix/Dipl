import Foundation
import SwiftUICore
import CoreLocation

struct User: Codable, Identifiable {
    let id: String
    let fullName: String
    let phoneNumber: String
    let email: String
    let registrationNumber: String
    let balance: Double
}

struct Parking: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let address: String
    let longitude: Double
    let latitude: Double
    let price: Double
    let levelCount: Int
    let spaceCount: Int
    let levelNumbers: [Int]
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    static func == (lhs: Parking, rhs: Parking) -> Bool {
        lhs.id == rhs.id
    }
}

struct ParkingLevel: Codable {
    let levelNumber: Int
    let levelSchema: String
    let parkingSpots: [ParkingSpot]
}

struct ParkingSpot: Codable, Identifiable {
    let id: Int
    let spotNumber: String
    let status: String
    let width: Double
    let height: Double
    let xcoordinate: Double
    let ycoordinate: Double
    
    var spotStatus: SpotStatus {
        SpotStatus(rawValue: status.lowercased()) ?? .occupied
    }
}

enum SpotStatus: String {
    case free = "free"
    case booked = "booked"
    case occupied = "occupied"
    
    var color: Color {
        switch self {
        case .free: return .green
        case .booked: return .orange
        case .occupied: return .red
        }
    }
}

struct Reservation: Codable, Identifiable {
    let id: Int
     let parkingName: String
     let parkingAddress: String
     let levelNumber: Int
     let spotId: Int
     let spotNumber: String
     let reservationStart: Date
     let parkingStart: Date?
     let parkingEnd: Date?
     let status: String
     
     enum CodingKeys: String, CodingKey {
         case id
         case parkingName
         case parkingAddress
         case levelNumber
         case spotId
         case spotNumber
         case reservationStart
         case parkingStart
         case parkingEnd
         case status
     }
     
     init(from decoder: Decoder) throws {
         let container = try decoder.container(keyedBy: CodingKeys.self)
         id = try container.decode(Int.self, forKey: .id)
         parkingName = try container.decode(String.self, forKey: .parkingName)
         parkingAddress = try container.decode(String.self, forKey: .parkingAddress)
         levelNumber = try container.decode(Int.self, forKey: .levelNumber)
         spotId = try container.decode(Int.self, forKey: .spotId)
         spotNumber = try container.decode(String.self, forKey: .spotNumber)
         
         let dateFormatter = ISO8601DateFormatter()
         dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
         
         let reservationStartString = try container.decode(String.self, forKey: .reservationStart)
         reservationStart = dateFormatter.date(from: reservationStartString) ?? Date()
         
         if let parkingStartString = try? container.decode(String?.self, forKey: .parkingStart) {
             parkingStart = dateFormatter.date(from: parkingStartString)
         } else {
             parkingStart = nil
         }
         
         if let parkingEndString = try? container.decode(String?.self, forKey: .parkingEnd) {
             parkingEnd = dateFormatter.date(from: parkingEndString)
         } else {
             parkingEnd = nil
         }
         
         status = try container.decode(String.self, forKey: .status)
     }
 }
