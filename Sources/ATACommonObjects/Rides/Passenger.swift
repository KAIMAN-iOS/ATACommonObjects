//
//  Passenger.swift
//  taxi.Chauffeur
//
//  Created by GG on 21/12/2020.
//

import Foundation

public struct Passenger: Codable {
    public let id: Int
    public let firstname: String
    public let lastname: String
    public let phone: String
    public var picture: String? = nil
    public var pictureUrl: URL? { URL(string: picture ?? "") }
    
    public init(id: Int,
         firstname: String,
         lastname: String,
         phone: String,
         picture: URL?) {
        self.id = id
        self.firstname = firstname
        self.lastname = lastname
        self.phone = phone
        self.picture = picture?.absoluteString
    }
}
