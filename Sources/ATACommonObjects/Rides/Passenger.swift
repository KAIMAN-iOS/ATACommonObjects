//
//  Passenger.swift
//  taxi.Chauffeur
//
//  Created by GG on 21/12/2020.
//

import Foundation

public struct Passenger: Codable {
    public var id: Int
    public var firstname: String
    public var lastname: String
    public var phone: String
    public var picture: String? = nil
    public var pictureUrl: URL? { URL(string: picture ?? "") }
    
    public init(id: Int = UUID().uuidString.hash,
         firstname: String = "",
         lastname: String = "",
         phone: String = "",
         picture: URL? = nil) {
        self.id = id
        self.firstname = firstname
        self.lastname = lastname
        self.phone = phone
        self.picture = picture?.absoluteString
    }
}
