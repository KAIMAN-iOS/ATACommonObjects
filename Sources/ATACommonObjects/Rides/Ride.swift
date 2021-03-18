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

public struct Coordinates: Codable {
    public let latitude: Double
    public let longitude: Double
    
    public init(location: CLLocationCoordinate2D) {
        latitude = location.latitude
        longitude = location.longitude
    }
}

public struct Address: Codable {
    public let address: String?
    public let coordinates: Coordinates
    
    public init( address: String?,
                 coordinates: Coordinates) {
        self.address = address
        self.coordinates = coordinates
    }
    public var asCoordinates2D: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude) }
}

public struct CancelRideReason {
    public let message: String
    public let code: Int
}

public struct Rideoptions: Codable {
    public let numberOfPassengers: Int
    public let numberOfLuggages: Int
    public let vehicleType: VehicleType?
    
    public init(numberOfPassengers: Int,
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
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        //mandatory
        numberOfPassengers = try container.decodeIfPresent(Int.self, forKey: .numberOfPassengers) ?? 1
        numberOfLuggages = try container.decodeIfPresent(Int.self, forKey: .numberOfLuggages) ?? 0
        vehicleType = try container.decodeIfPresent(VehicleType.self, forKey: .vehicleType)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(numberOfLuggages, forKey: .numberOfLuggages)
        try container.encode(numberOfPassengers, forKey: .numberOfPassengers)
        try container.encodeIfPresent(vehicleType, forKey: .vehicleType)
    }

}


// MARK: - BaseRide
public class BaseRide: NSObject, Codable {
    public static func == (lhs: BaseRide, rhs: BaseRide) -> Bool {
        return lhs.hash == rhs.hash
    }
    public var id: Int = UUID().uuidString.hashValue
    public let date: CustomDate<ISODateFormatterDecodable>!
    public var isImmediate: Bool = true
    public let fromAddress: Address!
    public let toAddress: Address?
    @DecodableDefault.EmptyList public var vehicleOptions: [VehicleOption]
    public var origin: String = ""
    public var state: RideState = .pending
    public let numberOfPassengers: Int!
    public let numberOfLuggages: Int!
    public var rideType: RideHistoryType? {
        switch state {
        case .booked: return .booked
        case .cancelled: return .cancelled
        case .ended: return .completed
        default: return nil
        }
    }
    
    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(id)
        return hasher.finalize()
    }
    
    public var username: String { "" }
    public var userIconURL: String? { nil }
}


public enum RideState: Int, Codable, CaseIterable, Comparable {
    public static func < (lhs: RideState, rhs: RideState) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    case pending = 1, booked, started, approach, delayed, waiting, pickUpPassenger, pendingPayment, ended, cancelled
    
    public var displayText: String? {
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
    
    public var next: RideState? {
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
public typealias Ride = RideProposal
public class RideProposal: CreateRide {
    public var validUntil: CustomDate<ISODateFormatterDecodable>!
    // the date the ride has been received
    public let receivedDate: Date = Date()
    @objc public dynamic var progress: Double = 0.0
}

public class CreateRide: BaseRide {
    public var vehicleType: VehicleType?
    public var passenger: Passenger?
    public var memo: String?
    public var reference: String?
}

public class OngoingRide: RideProposal {
    public var vehicle: BaseVehicle!
}

public class RideHistoryModel: OngoingRide {
    public var cancellationReason: String?
    public var pickUpAddress: Address?
    public var vatValue: Double?
    public var stats: [PendingPaymentRideData] = []
    public var priceDisplay: String? {
        guard let amount = stats.filter({ $0.type == .amount }).first else { return nil }
        return "\(amount.displayValue) \(amount.unit)"
    }
}

public struct PendingPaymentRideData: Codable {
    public var value: Double
    public var additionnalValue: Double? // used for VAT
    public let unit: String
    public let type: RideEndStat
    public var vatValue: Double?
    public var displayValue: String {
        let hasDigits = value - Double(Int(value)) > 0
        return String(format: hasDigits ? "%0.2f" : "%d", (hasDigits ? value : Int(value)))
    }
}

public enum RideEndStat: Int, Codable {
    case amount = 0, distance, time
    
    public var title: String {
        switch self {
        case .amount: return "amount stat".bundleLocale()
        case .distance: return "distance stat".bundleLocale()
        case .time: return "time stat".bundleLocale()
        }
    }
}

public enum RideHistoryType: Int, CaseIterable, Comparable {
    public static func < (lhs: RideHistoryType, rhs: RideHistoryType) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    case booked = 0, completed, cancelled
    public var canCancel: Bool {
        return self == .booked
    }
    
    public var title: String {
        switch self {
        case .booked: return "booked".bundleLocale().uppercased()
        case .completed: return "completed".bundleLocale().uppercased()
        case .cancelled: return "cancelled".bundleLocale().uppercased()
        }
    }
    
    public var subtitle: String {
        switch self {
        case .booked: return "booked subtitle".bundleLocale().uppercased()
        case .completed: return "completed subtitle".bundleLocale().uppercased()
        case .cancelled: return "cancelled subtitle".bundleLocale().uppercased()
        }
    }
}
