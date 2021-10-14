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
import StringExtension

extension String {
    func bundleLocale() -> String {
        NSLocalizedString(self, bundle: .module, comment: self)
    }
}

public struct Coordinates: Codable, Hashable, Equatable {
    public static func == (lhs: Coordinates, rhs: Coordinates) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    public let latitude: Double
    public let longitude: Double
    
    public init(location: CLLocationCoordinate2D) {
        latitude = location.latitude
        longitude = location.longitude
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
    
    public var asCoord2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

open class Address: NSObject, Codable {
    public static func == (lhs: Address, rhs: Address) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    open override func isEqual(_ object: Any?) -> Bool {
        guard let adress = object as? Address else { return false}
        return self == adress
    }
    public static let newId: Int = 98765432123456789
    public var id: Int = Address.newId
    public var name: String?
    public var address: String?
    public var coordinates: Coordinates
    public var code: String?
    public var cp: String?
    public var countryCode: String? = nil
    public var isValid: Bool { return CLLocationCoordinate2DIsValid(coordinates.asCoord2D) }
    
    enum CodingKeys: String, CodingKey {
        case name, address, coordinates, id, code
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        let adr = try container.decodeIfPresent(String.self, forKey: .address) ?? "n/a"
        address = adr
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? adr
        coordinates = try container.decode(Coordinates.self, forKey: .coordinates)
        code = try container.decodeIfPresent(String.self, forKey: .code)
    }
    
    open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(address, forKey: .address)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(code, forKey: .code)
        try container.encode(coordinates, forKey: .coordinates)
    }
    
    public init(name: String? = nil,
                address: String? = nil,
                coordinates: Coordinates,
                countryCode: String? = nil,
                cp: String? = nil) {
        self.address = address
        self.coordinates = coordinates
        self.name = name
        self.countryCode = countryCode
        self.cp = cp
    }
    public var asCoordinates2D: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude) }
    open override var hash: Int {
        var hasher = Hasher()
        hasher.combine(coordinates)
        hasher.combine(name)
        hasher.combine(address)
//        hasher.combine(id)
        return hasher.finalize()
    }
}

public class SearchOptions: NSObject, Codable {
    public var vehicleOptions: [VehicleOption] = []
    public var vehicleType: VehicleType?
    public var memo: String?
    public var reference: String?
    static var `default` = SearchOptions()
    
    override init() {}
    
    enum CodingKeys: String, CodingKey {
        case vehicleOptions, vehicleType, memo, reference
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        //mandatory
        vehicleOptions = try container.decodeIfPresent([VehicleOption].self, forKey: .vehicleOptions) ?? []
        vehicleType = try container.decodeIfPresent(VehicleType.self, forKey: .vehicleType)
        memo = try container.decodeIfPresent(String.self, forKey: .memo)
        reference = try container.decodeIfPresent(String.self, forKey: .reference)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(vehicleOptions, forKey: .vehicleOptions)
        try container.encodeIfPresent(vehicleType, forKey: .vehicleType)
        try container.encodeIfPresent(memo, forKey: .memo)
        try container.encodeIfPresent(reference, forKey: .reference)
    }
}

public class Payment: NSObject, Codable {
    public var vatValue: Double?
    public var stats: [PendingPaymentRideData] = []
    
    enum CodingKeys: String, CodingKey {
        case vatValue, stats
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        vatValue = try container.decode(Double.self, forKey: .vatValue)
        stats = try container.decode([PendingPaymentRideData].self, forKey: .stats)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(vatValue, forKey: .vatValue)
        try container.encode(stats, forKey: .stats)
    }
}

public struct PendingPaymentRideData: Codable {
    public var value: Double
    public var additionnalValue: Double? // used for VAT
    public var unit: String
    public var type: RideEndStat
    public var vatValue: Double?
    public var displayValue: String {
        let hasDigits = value - Double(Int(value)) > 0
        return String(format: hasDigits ? "%0.2f" : "%d", (hasDigits ? value : Int(value)))
    }
    public init(value: Double, additionnalValue: Double?, unit: String, type: RideEndStat) {
        self.value = value
        self.additionnalValue = additionnalValue
        self.unit = unit
        self.type = type
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

public class Proposal: NSObject, Codable {
    public var saveForMe: Bool?
    public var shareGroups: [String] = []
    
    public init(saveForMe: Bool, shareGroups: [String]) {
        self.saveForMe = saveForMe
        self.shareGroups = shareGroups
    }
    
    enum CodingKeys: String, CodingKey {
        case saveForMe, shareGroups
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        saveForMe = try container.decode(Bool.self, forKey: .saveForMe)
        shareGroups = try container.decode([String].self, forKey: .shareGroups)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(saveForMe, forKey: .saveForMe)
        try container.encode(shareGroups, forKey: .shareGroups)
    }
}

public enum RideOrigin: Int, Codable {
    case booker = 1
    case apps = 2
    case letaxi = 3
    
    public var displayText: String {
        switch self {
        case .booker: return "booker display".bundleLocale().uppercased()
        case .apps: return "apps display".bundleLocale().uppercased()
        case .letaxi: return "letaxi display".bundleLocale().uppercased()
        }
    }
}

// MARK: - BaseRide
open class BaseRide: NSObject, Codable {
    public static func == (lhs: BaseRide, rhs: BaseRide) -> Bool {
        return lhs.hash == rhs.hash
    }
    public var id: Int = UUID().uuidString.hashValue
    public var startDate: CustomDate<GMTISODateFormatterDecodable>!
    public var isImmediate: Bool = true
    @objc dynamic public var fromAddress: Address!
    @objc dynamic public var toAddress: Address?
    public var origin: RideOrigin = .apps
    public var state: RideState = .pending
    public var numberOfPassengers: Int = 1
    public var numberOfLuggages: Int = 0
    
    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(id)
        return hasher.finalize()
    }
    
    override init() {
        super.init()
    }
    static var `default` = BaseRide()
    
    
    public convenience init(id: Int,
                date: Date,
                isImmediate: Bool,
                fromAddress: Address,
                toAddress: Address?,
                origin: RideOrigin = .apps,
                state: RideState = .pending,
                numberOfPassengers: Int,
                numberOfLuggages: Int) {
        self.init()
        self.id = id
        self.startDate = CustomDate<GMTISODateFormatterDecodable>(date: date)
        self.isImmediate = isImmediate
        self.fromAddress = fromAddress
        self.toAddress = toAddress
        self.origin = origin
        self.state = state
        self.numberOfPassengers = numberOfPassengers
        self.numberOfLuggages = numberOfLuggages
    }
    
    enum CodingKeys: String, CodingKey {
        case id, startDate, isImmediate, fromAddress, toAddress, vehicleOptions, origin, state, numberOfPassengers, numberOfLuggages
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            id = try container.decode(Int.self, forKey: .id)
            startDate = try container.decode(CustomDate<GMTISODateFormatterDecodable>.self, forKey: .startDate)
            isImmediate = try container.decode(Bool.self, forKey: .isImmediate)
            fromAddress = try container.decode(Address.self, forKey: .fromAddress)
            toAddress = try container.decode(Address.self, forKey: .toAddress)
            origin = try container.decodeIfPresent(RideOrigin.self, forKey: .origin) ?? .apps
            state = try container.decode(RideState.self, forKey: .state)
            numberOfPassengers = try container.decode(Int.self, forKey: .numberOfPassengers)
            numberOfLuggages = try container.decode(Int.self, forKey: .numberOfLuggages)
        } catch {
            throw error
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(startDate, forKey: .startDate)
        try container.encodeIfPresent(isImmediate, forKey: .isImmediate)
        try container.encodeIfPresent(fromAddress, forKey: .fromAddress)
        try container.encodeIfPresent(toAddress, forKey: .toAddress)
        try container.encodeIfPresent(origin, forKey: .origin)
        try container.encodeIfPresent(state, forKey: .state)
        try container.encodeIfPresent(numberOfPassengers, forKey: .numberOfPassengers)
        try container.encodeIfPresent(numberOfLuggages, forKey: .numberOfLuggages)
    }
}


public enum RideState: Int, Codable, CaseIterable, Comparable {
    public static func < (lhs: RideState, rhs: RideState) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    case pending = 1, booked, started, approach, delayed, waiting, pickUpPassenger, pendingPayment, ended, cancelled, marketPlace
    
    public var displayText: String? {
        switch self {
        case .started: return "ride state started".bundleLocale()
        case .approach: return "ride state approach".bundleLocale()
        case .pickUpPassenger: return "ride state pickUpPassenger".bundleLocale()
        case .ended: return "ride state ended".bundleLocale()
        case .cancelled: return "ride state cancelled".bundleLocale()
        case .booked: return "ride state booked".bundleLocale()
        case .pending: return "ride state pending".bundleLocale()
        case .marketPlace: return "ride state marketPlace".bundleLocale()
        default: return nil
        }
    }
    
    public var subtitle: String? {
        switch self {
        case .ended: return "ride state ended".bundleLocale()
        case .cancelled: return "ride state cancelled".bundleLocale()
        case .booked: return "ride state booked".bundleLocale()
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
        case .marketPlace: return nil
        }
    }
}

protocol RideContainable {
    var ride: BaseRide { get }
}

open class CreateRide: Codable, RideContainable {
    public var ride: BaseRide
    public var options: SearchOptions
    public var passenger: BasePassenger?
    public var driver: BaseDriver?
    
    enum CodingKeys: String, CodingKey {
        case options = "searchOptions", ride, passenger, driver
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        //mandatory
        ride = try container.decode(BaseRide.self, forKey: .ride)
        options = try container.decode(SearchOptions.self, forKey: .options)
        passenger = try container.decodeIfPresent(BasePassenger.self, forKey: .passenger)
        driver = try container.decodeIfPresent(BaseDriver.self, forKey: .driver)
    }

    
    public init(passenger: BasePassenger? = nil) {
        ride = BaseRide.default
        options = SearchOptions.default
        self.passenger = passenger ?? BasePassenger.default
    }
}

// MARK: - New Ride
// MARK: ride proposal for driver
public typealias Ride = RideProposal
public class RideProposal: NSObject, Codable, RideContainable {
    public var ride: BaseRide
    public var options: SearchOptions
    public var passenger: BasePassenger?
    public var validUntil: CustomDate<GMTISODateFormatterDecodable>!
    // the date the ride has been received
    public let receivedDate: Date = Date()
    @objc public dynamic var progress: Double = 0.0
    public static var rideChannelPrefix = "_rideChannel_"
    
    enum CodingKeys: String, CodingKey {
        case ride
        case options = "searchOptions"
        case passenger
        case validUntil
    }
    
    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(ride)
        return hasher.finalize()
    }
    public static func == (lhs: RideProposal, rhs: RideProposal) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

public class OngoingRide: Codable, RideContainable {
    public var vehicle: BaseVehicle!
    public var ride: BaseRide
    public var passenger: BasePassenger?
    public var driver: BaseDriver?
    public var options: SearchOptions
    
    enum CodingKeys: String, CodingKey {
        case ride
        case options = "searchOptions"
        case passenger
        case vehicle
        case driver
    }
}

public enum RideCancelReason: Int, Codable {
    case none = 0
    // GLOBAL
    case cancelPendingRideByPassenger = 100
    case noDriverFound = 101
    // DRIVER
    case engineBreakdown = 200
    case passengerNotFound = 201
    case otherReasonbyDriver = 202
    // PASSENGER
    case cancelledyPassenger = 300
}

public class RideHistoryModel: Codable, RideContainable {
    public var vehicle: BaseVehicle!
    public var ride: BaseRide
    public var passenger: BasePassenger?
    public var driver: BaseDriver?
    public var payment: Payment
    public var cancellationReason: RideCancelReason?
    public var pickUpAddress: Address?
    public var priceDisplay: String? {
        guard let amount = payment.stats.filter({ $0.type == .amount }).first else { return nil }
        return "\(amount.displayValue) \(amount.unit)"
    }
}
