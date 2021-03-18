//
//  ContactModel.swift
//  taxi.Chauffeur
//
//  Created by GG on 10/11/2020.
//

import UIKit

extension Bundle {
    var appVersion: String {
        "\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "").\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "")"
    }
}

struct ContactModel: Encodable {
    let text: String
    let appVersion: String = Bundle.main.appVersion
    let systemVersion: String = UIDevice.current.systemVersion
    
    init(text: String) {
        self.text = text
    }
    
    
    enum CodingKeys: String, CodingKey {
        case text
        case appVersion
        case systemVersion
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encode(appVersion, forKey: .appVersion)
        try container.encode(systemVersion, forKey: .systemVersion)
    }
}

struct RideContactModel: Encodable {
    let text: String
    let rideId: Int
    
    init(text: String, rideId: Int) {
        self.text = text
        self.rideId = rideId
    }
    
    enum CodingKeys: String, CodingKey {
        case text
        case rideId
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encode(rideId, forKey: .rideId)
    }
}
