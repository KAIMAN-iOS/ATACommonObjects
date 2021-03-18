//
//  Passenger.swift
//  taxi.Chauffeur
//
//  Created by GG on 21/12/2020.
//

import Foundation

struct Passenger: Codable {
    let id: Int
    let firstname: String
    let lastname: String
    let phone: String
    var picture: String? = nil
    var pictureUrl: URL? { URL(string: picture ?? "") }
    
    init(id: Int,
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
