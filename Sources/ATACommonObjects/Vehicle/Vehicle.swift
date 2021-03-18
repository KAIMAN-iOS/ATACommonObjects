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

extension Array where Element == BaseVehicle {
    var current: BaseVehicle? {
        filter({ $0.isCurrentVehicle }).first
    }
}

struct BaseVehicle: Codable, Hashable {
    static func == (lhs: BaseVehicle, rhs: BaseVehicle) -> Bool {
        let retVal = lhs.id == rhs.id &&
            lhs.brand == rhs.brand &&
            lhs.model == rhs.model &&
            lhs.color == rhs.color &&
            lhs.plate == rhs.plate &&
            lhs.numberOfSeats == rhs.numberOfSeats
        print("👺 Equatable \(retVal) - \(lhs.model)/\(lhs.id) - \(rhs.model)/\(rhs.id) ")
        return retVal
    }
    
    var id: String
    var brand: VehicleBrand? = VehicleBrand.allCases.first
    var model: String
    var vehicleType: VehicleType? = VehicleType.allCases.first
    var color: VehicleColor? = VehicleColor.allCases.first
    var plate: String
    var numberOfSeats: Int = 4
    var isCurrentVehicle: Bool
    @DecodableDefault.False var isValidated: Bool
    var longDescription: String {
        "\(model) (\(color?.displayText ?? "")) - \(plate)"
     }
    var isMedical: Bool { activeOptions.contains(.cpam) }
    @DecodableDefault.EmptyList var activeOptions: [VehicleOption]
    
    func hash(into hasher: inout Hasher) {
//        print("👺 hash \(model)/\(id)")
        hasher.combine(id)
//        hasher.combine(model)
//        hasher.combine(color)
    }
    
    var allFieldsSet: Bool {
        return brand != nil &&
            vehicleType != nil &&
            model.isEmpty == false &&
            color != nil &&
            plate.isEmpty == false
    }
    
    init() {
        id = ""
        model = ""
        plate = ""
        isCurrentVehicle = false
    }
    
    var multipartData: MultipartFormData {
        let data = MultipartFormData()
        try? data.encode(id, for: "id")
        try? data.encode(brand, for: "brand")
        try? data.encode(model, for: "model")
        try? data.encode(color, for: "color")
        try? data.encode(vehicleType, for: "vehicleType")
        try? data.encode(plate, for: "plate")
        try? data.encode(isMedical, for: "isMedical")
        try? data.encode(numberOfSeats, for: "numberOfSeats")
        try? data.encode(isCurrentVehicle, for: "isCurrentVehicle")
        return data
    }
}

enum VehicleColor: String, Codable, CaseIterable {
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
    
    static func from(rawValue: String) -> VehicleColor {
        return self.init(rawValue: rawValue.uppercased()) ?? .other
    }
    
    var displayText: String {
        return "\(rawValue) COLOUR".bundleLocale().uppercased()
    }
}

enum VehicleType: Int, Codable, CaseIterable {
    case berline = 1, green, prestige, van
    
    var displayValue: String {
        switch self {
        case .berline: return "BERLINE".bundleLocale()
        case .green: return "GREEN".bundleLocale()
        case .prestige: return "PRESTIGE".bundleLocale()
        case .van: return "VAN".bundleLocale()
        }
    }
    
    var displayText: String { displayValue.uppercased() }
    static func from(rawValue: Int) -> VehicleType { VehicleType.allCases.filter({ $0.rawValue == rawValue }).first ?? .berline }
    init?(rawValue: Int) {
        self = VehicleType.from(rawValue: rawValue)
    }
}

enum VehicleBrand: String, Codable, CaseIterable, Comparable {
    static func < (lhs: VehicleBrand, rhs: VehicleBrand) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    static var separator: String = "---"
    static var displayAllCases: [String] {
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
    
    var displayText: String {
        switch self {
        case .other: return "Vehicle other".bundleLocale().uppercased()
        default: return rawValue.uppercased()
        }
    }
    
    static func brand(at index: Int) -> VehicleBrand? {
        if index < VehicleBrand.mainBrands.count {
            return VehicleBrand.mainBrands[index]
        }
        if index == VehicleBrand.mainBrands.count {
            return nil
        }
        return VehicleBrand.otherBrands[index - VehicleBrand.mainBrands.count - 1]
    }
    
    static func index(of brand: VehicleBrand?) -> Int? {
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
    
    static func from(rawValue: String) -> VehicleBrand {
        return self.init(rawValue: rawValue.uppercased()) ?? .other
    }
    
    static var mainBrands: [VehicleBrand] { VehicleBrand.allCases.filter({ $0.isMainBrand }).sorted() }
    static var otherBrands: [VehicleBrand] { VehicleBrand.allCases.filter({ $0.isMainBrand == false }).sorted().filter({ $0 != .other }) + [.other] }
}

enum VehicleOption: Int, CaseIterable, Codable {
    case cpam = 1, covidShield, englishSpoken, mkids1, mkids2, mkids3, mkids4, pets, access
    
    var title: String {
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
}
