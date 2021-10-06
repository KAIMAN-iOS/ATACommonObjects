//
//  CityCode.swift
//  taxi.Chauffeur
//
//  Created by GG on 06/09/2021.
//

import UIKit

public struct CityCode: Decodable, Hashable {
    public let name: String
    public let code: String
    public let cp: [String]
    
    enum CodingKeys: String, CodingKey {
        case name = "nom"
        case code
        case cp = "codesPostaux"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        //mandatory
        name = try container.decode(String.self, forKey: .name)
        code = try container.decode(String.self, forKey: .code)
        cp = try container.decode([String].self, forKey: .cp)
    }
    
    public static func usesCityCodes(country: String) -> Bool {
        Bundle.module.url(forResource: "CP-\(country)", withExtension: "txt") != nil
    }
    
    public static func citycodesForCountry(country: String) -> [CityCode]? {
        guard let file = Bundle.module.url(forResource: "CP-\(country)", withExtension: "txt"),
              let data = try? Data(contentsOf: file),
              let json = try? JSONDecoder().decode([CityCode].self, from: data) else { return nil }
        return json.sorted(by: { $0.name.compare($1.name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedAscending })
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(code)
    }
}

public extension Array where Element == CityCode {
    func code(for cp: String) -> String? { first(where: { $0.cp.contains(cp) })?.code }
}
