//
//  Vehicle.swift
//  taxi.Chauffeur
//
//  Created by GG on 03/11/2020.
//

import UIKit
import NSAttributedStringBuilder
import FontExtension
import Ampersand
import Alamofire
import CodableExtension

open class BaseVehicle: Codable, Hashable {
    static let newVehicle = "#>NewVehicle<#"
    public static func == (lhs: BaseVehicle, rhs: BaseVehicle) -> Bool {
        let retVal = lhs.id == rhs.id &&
            lhs.brand == rhs.brand &&
            lhs.model == rhs.model &&
            lhs.color == rhs.color &&
            lhs.plate == rhs.plate &&
            lhs.numberOfSeats == rhs.numberOfSeats
        print("👺 Equatable \(retVal) - \(lhs.model)/\(lhs.id) - \(rhs.model)/\(rhs.id) ")
        return retVal
    }
    public var isNew: Bool {  id == BaseVehicle.newVehicle }
    public var id: String = BaseVehicle.newVehicle
    public var brand: VehicleBrand? = VehicleBrand.allCases.first
    public var model: String
    public var vehicleType: VehicleType? = VehicleType.allCases.first
    public var color: VehicleColor? = VehicleColor.allCases.first
    public var plate: String
    public var numberOfSeats: Int = 4
    @DecodableDefault.False public var isValidated: Bool
    public var longDescription: String {
        "\(model) (\(color?.displayText ?? "")) - \(plate)"
     }
    public var isMedical: Bool { activeOptions.contains(.cpam) }
    @DecodableDefault.EmptyList public var activeOptions: [VehicleOption]
    
    open func hash(into hasher: inout Hasher) {
//        print("👺 hash \(model)/\(id)")
        hasher.combine(id)
//        hasher.combine(model)
//        hasher.combine(color)
    }
    
    open var allFieldsSet: Bool {
        return brand != nil &&
            vehicleType != nil &&
            model.isEmpty == false &&
            color != nil &&
            plate.isEmpty == false
    }
    
    public init() {
        id = ""
        model = ""
        plate = ""
    }
    
    open var multipartData: MultipartFormData {
        let data = MultipartFormData()
        try? data.encode(id, for: "id")
        try? data.encode(brand, for: "brand")
        try? data.encode(model, for: "model")
        try? data.encode(color, for: "color")
        try? data.encode(vehicleType, for: "vehicleType")
        try? data.encode(plate, for: "plate")
        try? data.encode(isMedical, for: "isMedical")
        try? data.encode(numberOfSeats, for: "numberOfSeats")
        return data
    }
}

public enum VehicleColor: String, Codable, CaseIterable {
    case white = "WHITE"
    case black = "BLACK"
    case blue = "BLUE"
    case green = "GREEN"
    case orange = "ORANGE"
    case yellow = "YELLOW"
    case red = "RED"
    case gray = "GRAY"
    case brown = "BROWN"
    case other = "OTHER"
    
    public static func from(rawValue: String) -> VehicleColor {
        return self.init(rawValue: rawValue.uppercased()) ?? .other
    }
    
    public var displayText: String {
        return "\(rawValue) COLOUR".bundleLocale().uppercased()
    }
}

public enum VehicleType: Int, Codable, CaseIterable {
    case berline = 1, green, prestige, van
    
    public var displayValue: String {
        switch self {
        case .berline: return "BERLINE".bundleLocale()
        case .green: return "GREEN".bundleLocale()
        case .prestige: return "PRESTIGE".bundleLocale()
        case .van: return "VAN".bundleLocale()
        }
    }
    
    public var displayText: String { displayValue.uppercased() }
    public static func from(rawValue: Int) -> VehicleType { VehicleType.allCases.filter({ $0.rawValue == rawValue }).first ?? .berline }
    public init?(rawValue: Int) {
        self = VehicleType.from(rawValue: rawValue)
    }
}

public enum VehicleBrand: String, Codable, CaseIterable, Comparable {
    public static func < (lhs: VehicleBrand, rhs: VehicleBrand) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    public static var separator: String = "---"
    public static var displayAllCases: [String] {
        VehicleBrand.mainBrands.compactMap({ $0.displayText })
            + [VehicleBrand.separator]
            + VehicleBrand.otherBrands.compactMap({ $0.displayText })
    }
    
    case audi = "AUDI"
    case bmw = "BMW"
    case citroen = "CITROEN"
    case mercedes = "MERCEDES"
    case peugeot = "PEUGEOT"
    case renault = "RENAULT"
    case volkswagen = "VOLKSWAGEN"
    case abarth = "ABARTH"
    case alfa = "ALFA"
    case bentley = "BENTLEY"
    case chevrolet = "CHEVROLET"
    case cupra = "CUPRA"
    case dacia = "DACIA"
    case ds = "DS"
    case fiat = "FIAT"
    case ford = "FORD"
    case honda = "HONDA"
    case hyundai = "HYUNDAI"
    case infiniti = "INFINITI"
    case jaguar = "JAGUAR"
    case jeep = "JEEP"
    case kia = "KIA"
    case land = "LAND"
    case lexus = "LEXUS"
    case maserati = "MASERATI"
    case mazda = "MAZDA"
    case mini = "MINI"
    case mitsubishi = "MITSUBISHI"
    case nissan = "NISSAN"
    case opel = "OPEL"
    case porsche = "PORSCHE"
    case seat = "SEAT"
    case skoda = "SKODA"
    case smart = "SMART"
    case ssangyong = "SSANGYONG"
    case suzuki = "SUZUKI"
    case tesla = "TESLA"
    case toyota = "TOYOTA"
    case volvo = "VOLVO"
    case other = "OTHER"
    
    public var displayText: String {
        switch self {
        case .other: return "Vehicle other".bundleLocale().uppercased()
        default: return rawValue.uppercased()
        }
    }
    
    public static func brand(at index: Int) -> VehicleBrand? {
        if index < VehicleBrand.mainBrands.count {
            return VehicleBrand.mainBrands[index]
        }
        if index == VehicleBrand.mainBrands.count {
            return nil
        }
        return VehicleBrand.otherBrands[index - VehicleBrand.mainBrands.count - 1]
    }
    
    public static func index(of brand: VehicleBrand?) -> Int? {
        guard let brand = brand else { return nil }
        if let index =  VehicleBrand.mainBrands.firstIndex(of: brand) {
            return index
        }
        if let index =  VehicleBrand.otherBrands.firstIndex(of: brand) {
            return index + VehicleBrand.mainBrands.count + 1
        }
        return nil
    }
    
    private var isMainBrand: Bool {
        switch self {
        case .audi, .bmw, .citroen, .mercedes, .peugeot, .renault, .volkswagen: return true
        default: return false
        }
    }
    
    public static func from(rawValue: String) -> VehicleBrand {
        return self.init(rawValue: rawValue.uppercased()) ?? .other
    }
    
    public static var mainBrands: [VehicleBrand] { VehicleBrand.allCases.filter({ $0.isMainBrand }).sorted() }
    public static var otherBrands: [VehicleBrand] { VehicleBrand.allCases.filter({ $0.isMainBrand == false }).sorted().filter({ $0 != .other }) + [.other] }
}

public enum VehicleOption: Int, CaseIterable, Codable {
    case cpam = 1, covidShield, englishSpoken, mkids1, mkids2, mkids3, mkids4, pets, access
    
    public var title: String {
        switch self {
        case .cpam: return "cpam option".bundleLocale()
        case .covidShield: return "covidShield option".bundleLocale()
        case .englishSpoken: return "englishSpoken option".bundleLocale()
        case .mkids1: return "mkids1 option".bundleLocale()
        case .mkids2: return "mkids2 option".bundleLocale()
        case .mkids3: return "mkids3 option".bundleLocale()
        case .mkids4: return "mkids4 option".bundleLocale()
        case .pets: return "pets option".bundleLocale()
        case .access: return "access option".bundleLocale()
        }
    }
    
    public var displayText: String {
        switch self {
        case .cpam: return "cpam option display".bundleLocale()
        case .covidShield: return "covidShield option display".bundleLocale()
        case .englishSpoken: return "englishSpoken option display".bundleLocale()
        case .mkids1: return "mkids1 option display".bundleLocale()
        case .mkids2: return "mkids2 option display".bundleLocale()
        case .mkids3: return "mkids3 option display".bundleLocale()
        case .mkids4: return "mkids4 option display".bundleLocale()
        case .pets: return "pets option display".bundleLocale()
        case .access: return "access option display".bundleLocale()
        }
    }
}
