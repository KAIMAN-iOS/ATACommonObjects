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
    public var id: Int = UUID().uuidString.hash
    public var name: String?
    public var address: String?
    public var coordinates: Coordinates
    public var isValid: Bool { return CLLocationCoordinate2DIsValid(coordinates.asCoord2D) }
    
    public init(name: String? = nil,
                address: String? = nil,
                coordinates: Coordinates) {
        self.address = address
        self.coordinates = coordinates
        self.name = name
    }
    
    public init(name: String? = nil,
                address: String? = nil,
                coordinates: CLLocationCoordinate2D) {
        self.address = address
        self.coordinates = Coordinates(location: coordinates)
        self.name = name
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

public struct CancelRideReason {
    public let message: String
    public let code: Int
    public init(message: String, code: Int) {
        self.message = message
        self.code = code
    }
}

public class SearchOptions: NSObject, Codable {
    public var vehicleOptions: [VehicleOption] = []
    public var vehicleType: VehicleType?
    public var memo: String?
    public var reference: String?
    static var `default` = SearchOptions()
    
    override init() {
        
    }
    
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
    public var origin: Int = 0
    public var state: RideState = .pending
    public var numberOfPassengers: Int = 1
    public var numberOfLuggages: Int = 0
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
    
    override init() {
        super.init()
    }
    static var `default` = BaseRide()
    
    
    public convenience init(id: Int,
                date: Date,
                isImmediate: Bool,
                fromAddress: Address,
                toAddress: Address?,
                origin: Int = 0,
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
            origin = try container.decode(Int.self, forKey: .origin)
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

protocol RideContainable {
    var ride: BaseRide { get }
}

open class CreateRide: Codable, RideContainable {
    public var ride: BaseRide
    public var options: SearchOptions
    public var passenger: BasePassenger?
    
    public init() {
        ride = BaseRide.default
        options = SearchOptions.default
        passenger = BasePassenger.default
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
    public var options: SearchOptions
    
    enum CodingKeys: String, CodingKey {
        case ride
        case options = "searchOptions"
        case passenger
        case vehicle
    }
}

public class RideHistoryModel: Codable, RideContainable {
    public var vehicle: BaseVehicle!
    public var ride: BaseRide
    public var passenger: BasePassenger?
    public var payment: Payment
    public var cancellationReason: String?
    public var pickUpAddress: Address?
    public var priceDisplay: String? {
        guard let amount = payment.stats.filter({ $0.type == .amount }).first else { return nil }
        return "\(amount.displayValue) \(amount.unit)"
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
//
//// random extension for mockup
//
//extension RideHistoryModel {
//    public static func random() -> RideHistoryModel {
//        let randomType = Int.random(in: 0...2)
//        return RideHistoryModel.init(id: UUID().uuidString.hash,
//                                     date: Int.random(in: 0...1) == 0 ? Date() : Date().addingTimeInterval(23*87*7),
//                                     isImmediate: Int.random(in: 0...1) == 0 ? true : false,
//                                     fromAddress: Address.random,
//                                     toAddress: Address.optionnalRandom,
//                                     state: randomType == 0 ? RideState.booked : (randomType == 1 ? .cancelled : .ended),
//                                     numberOfPassengers: Int.random(in: 1...5),
//                                     numberOfLuggages: Int.random(in: 0...6),
//                                     vehicle: BaseVehicle(),
//                                     passenger: Passenger(id: 89067, firstname: "Jean-Pierre", lastname: "BACRI", phone: "0987654321", picture: URL(string: "https://images.laprovence.com/media/afp/2021-01/2021-01-18/6b1814044de4a65ba1376d500122ec3972e17570.jpg?twic=v1/dpr=2/focus=900x576.5/cover=1000x562")),
//                                     memo: "this is the meme",
//                                     reference: "this is the reference",
//                                     cancellationReason: Int.random(in: 0...1) == 0 ? "Passager absent" : nil,
//                                     pickUpAddress: Address.optionnalRandom,
//                                     vatValue: Int.random(in: 0...1) == 0 ? 20 : nil)
//    }
//
//}
//
//public extension Address {
//    static var add1: Address {
//        Address(address: "la barque 13710 FUVEAU", coordinates: Coordinates(location: CLLocationCoordinate2D(latitude: 43.47865284174063, longitude: 5.53859787072443)))
//    }
//    static var add2: Address {
//        Address(address: "Place Saint-Jean de Malte, 13100 Aix-en-Provence", coordinates: Coordinates(location: CLLocationCoordinate2D(latitude: 43.52645372148015, longitude: 5.452597832139817)))
//    }
//    static var add3: Address {
//        Address(address: "départ adresse 13510 Fuveau", coordinates: Coordinates(location: CLLocationCoordinate2D(latitude: 43.454551591901144, longitude: 5.468953808988056)))
//    }
//    static var add4: Address {
//        Address(address: "rue Courbet 13736 Gardanne", coordinates: Coordinates(location: CLLocationCoordinate2D(latitude: 43.471590283851015, longitude: 5.4925626895974045)))
//    }
//    static var add5: Address {
//        Address(address: "Gare Saint Charles 13000 Marseille", coordinates: Coordinates(location: CLLocationCoordinate2D(latitude: 43.30295892353656, longitude: 5.380216342283413)))
//    }
//
//    static var random: Address {
//        return [Address.add1, Address.add2, Address.add3, Address.add4, Address.add5][Int.random(in: 0...4)]
//    }
//    static var optionnalRandom: Address? {
//        return [Address.add1, Address.add2, Address.add3, Address.add4, Address.add5, nil][Int.random(in: 0...5)]
//    }
//}
////
////public extension Rideoptions {
////    static var opt1: Rideoptions {
////        Rideoptions(numberOfPassengers: 1, numberOfLuggages: 1, vehicleType: nil)
////    }
////    static var opt2: Rideoptions {
////        Rideoptions(numberOfPassengers: 3, numberOfLuggages: 1, vehicleType: nil)
////    }
////    static var opt3: Rideoptions {
////        Rideoptions(numberOfPassengers: 2, numberOfLuggages: 0, vehicleType: nil)
////    }
////    static var opt4: Rideoptions {
////        Rideoptions(numberOfPassengers: 5, numberOfLuggages: 3, vehicleType: nil)
////    }
////    static var random: Rideoptions {
////        [Rideoptions.opt1, Rideoptions.opt2, Rideoptions.opt3, Rideoptions.opt4][Int.random(in: 0...3)]
////    }
////}
//
//public extension PendingPaymentRideData {
//    static var distanceStat: PendingPaymentRideData? {
//        [PendingPaymentRideData(value: 25, additionnalValue: nil, unit: "km", type: .distance),
//         PendingPaymentRideData(value: 216, additionnalValue: nil, unit: "km", type: .distance),
//         PendingPaymentRideData(value: 8, additionnalValue: nil, unit: "km", type: .distance),
//        nil][Int.random(in: 0...3)]
//    }
//    static var priceStat: PendingPaymentRideData? {
//        [PendingPaymentRideData(value: 25.9, additionnalValue: nil, unit: "€", type: .amount),
//         PendingPaymentRideData(value: 216.3, additionnalValue: nil, unit: "$", type: .amount),
//         PendingPaymentRideData(value: 8, additionnalValue: nil, unit: "£", type: .amount),
//         nil][Int.random(in: 0...3)]
//    }
//    static var timeStat: PendingPaymentRideData? {
//        [PendingPaymentRideData(value: 40, additionnalValue: nil, unit: "min", type: .time),
//         PendingPaymentRideData(value: 216, additionnalValue: nil, unit: "min", type: .time),
//         PendingPaymentRideData(value: 8, additionnalValue: nil, unit: "sec", type: .time),
//         nil][Int.random(in: 0...3)]
//    }
//}
