//
//  Ride.swift
//  taxi.Chauffeur
//
//  Created by GG on 11/12/2020.
//

import UIKit
import CoreLocation
import NSAttributedStringBuilder
import DateExtension
import CodableExtension

extension String {
    func bundleLocale() -> String {
        NSLocalizedString(self, bundle: .module, comment: self)
    }
}

struct Coordinates: Codable {
    let latitude: Double
    let longitude: Double
    
    init(location: CLLocationCoordinate2D) {
        latitude = location.latitude
        longitude = location.longitude
    }
}

struct Address: Codable {
    let address: String?
    let coordinates: Coordinates
    
    var asCoordinates2D: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude) }
}

struct CancelRideReason {
    let message: String
    let code: Int
}

struct Rideoptions: Codable {
    let numberOfPassengers: Int
    let numberOfLuggages: Int
    let vehicleType: VehicleType?
    
    init(numberOfPassengers: Int,
         numberOfLuggages: Int,
         vehicleType: VehicleType?) {
        self.numberOfLuggages = numberOfLuggages
        self.numberOfPassengers = numberOfPassengers
        self.vehicleType = vehicleType
    }
    
    enum CodingKeys: String, CodingKey {
        case numberOfPassengers
        case numberOfLuggages
        case vehicleType
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        //mandatory
        numberOfPassengers = try container.decodeIfPresent(Int.self, forKey: .numberOfPassengers) ?? 1
        numberOfLuggages = try container.decodeIfPresent(Int.self, forKey: .numberOfLuggages) ?? 0
        vehicleType = try container.decodeIfPresent(VehicleType.self, forKey: .vehicleType)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(numberOfLuggages, forKey: .numberOfLuggages)
        try container.encode(numberOfPassengers, forKey: .numberOfPassengers)
        try container.encodeIfPresent(vehicleType, forKey: .vehicleType)
    }

}


// MARK: - BaseRide
class BaseRide: NSObject, Codable {
    static func == (lhs: BaseRide, rhs: BaseRide) -> Bool {
        return lhs.hash == rhs.hash
    }
    var id: Int = UUID().uuidString.hashValue
    let date: CustomDate<ISODateFormatterDecodable>!
    var isImmediate: Bool = true
    let fromAddress: Address!
    let toAddress: Address?
    @DecodableDefault.EmptyList var vehicleOptions: [VehicleOption]
    var origin: String = ""
    var state: RideState = .pending
    let numberOfPassengers: Int!
    let numberOfLuggages: Int!
    
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(id)
        return hasher.finalize()
    }
    
    var username: String { "" }
    var userIconURL: String? { nil }
}


enum RideState: Int, Codable, CaseIterable, Comparable {
    static func < (lhs: RideState, rhs: RideState) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    case pending = 1, booked, started, approach, delayed, waiting, pickUpPassenger, pendingPayment, ended, cancelled
    
    var displayText: String? {
        switch self {
        case .started: return "ride state started".bundleLocale()
        case .approach: return "ride state approach".bundleLocale()
        case .pickUpPassenger: return "ride state pickUpPassenger".bundleLocale()
        case .ended: return "ride state ended".bundleLocale()
        case .cancelled: return "ride state cancelled".bundleLocale()
        case .booked: return "ride state booked".bundleLocale()
        case .pending: return "ride state pending".bundleLocale()
        default: return nil
        }
    }
    
    var next: RideState? {
        switch self {
        case .pending: return nil
        case .booked: return .started
        case .started: return .approach
        case .approach: return .pickUpPassenger
        case .delayed: return .pendingPayment
        case .waiting: return .pendingPayment
        case .pickUpPassenger: return .pendingPayment
        case .pendingPayment: return .ended
        case .ended: return nil
        case .cancelled: return nil
        }
    }
}

// MARK: - New Ride
// MARK: ride proposal for driver
typealias Ride = RideProposal
class RideProposal: CreateRide {
    var validUntil: CustomDate<ISODateFormatterDecodable>!
    // the date the ride has been received
    let receivedDate: Date = Date()
    @objc dynamic var progress: Double = 0.0
}

class CreateRide: BaseRide {
    var vehicleType: VehicleType?
    var passenger: Passenger?
}

class OngoingRide: BaseRide {
    var vehicle: BaseVehicle!
    var passenger: Passenger!
    var memo: String?
    var reference: String?
}

class RideHistoryModel: OngoingRide {
    var cancellationReason: String?
    var pickUpAddress: Address?
    var vatValue: Double?
    var stats: [PendingPaymentRideData] = []
}

struct PendingPaymentRideData: Codable {
    var value: Double
    var additionnalValue: Double? // used for VAT
    let unit: String
    let type: RideEndStat
    var vatValue: Double?
    var displayValue: String {
        let hasDigits = value - Double(Int(value)) > 0
        return String(format: hasDigits ? "%0.2f" : "%d", (hasDigits ? value : Int(value)))
    }
}

enum RideEndStat: Int, Codable {
    case amount = 0, distance, time
    
    var title: String {
        switch self {
        case .amount: return "amount stat".bundleLocale()
        case .distance: return "distance stat".bundleLocale()
        case .time: return "time stat".bundleLocale()
        }
    }
}
