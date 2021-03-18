//
//  ContactModel.swift
//  taxi.Chauffeur
//
//  Created by GG on 10/11/2020.
//

import UIKit

public extension Bundle {
    var appVersion: String {
        "\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "").\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "")"
    }
}

public struct ContactModel: Encodable {
    public let text: String
    public let appVersion: String = Bundle.main.appVersion
    public let systemVersion: String = UIDevice.current.systemVersion
    
    public init(text: String) {
        self.text = text
    }
    
    
    enum CodingKeys: String, CodingKey {
        case text
        case appVersion
        case systemVersion
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encode(appVersion, forKey: .appVersion)
        try container.encode(systemVersion, forKey: .systemVersion)
    }
}

public struct RideContactModel: Encodable {
    public let text: String
    public let rideId: Int
    
    public init(text: String, rideId: Int) {
        self.text = text
        self.rideId = rideId
    }
    
    enum CodingKeys: String, CodingKey {
        case text
        case rideId
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encode(rideId, forKey: .rideId)
    }
}
