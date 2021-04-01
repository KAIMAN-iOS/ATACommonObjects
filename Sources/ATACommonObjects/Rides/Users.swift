//
//  Passenger.swift
//  taxi.Chauffeur
//
//  Created by GG on 21/12/2020.
//

import Foundation
import PhoneNumberKit

public class BaseUser: Codable {
    static let numberKit = PhoneNumberKit()
    static let numberFormatter = PhoneNumberFormatter()
    var phoneFormatter: PartialFormatter  {
        let formatter = PartialFormatter()
        formatter.defaultRegion = countryCode
        return formatter
    }
    
    private var formartedNumber: String? {
        return BaseUser.numberFormatter.string(for: number)
    }
    
    private var number: PhoneNumber? {
        return try? BaseUser.numberKit.parse(phoneNumber)
    }
    
    var countryCode: String {
        didSet {
            BaseUser.numberFormatter.defaultRegion = countryCode
        }
    }
    var hasValidNumber: Bool {
        return BaseUser.numberKit.isValidPhoneNumber(phoneNumber, withRegion: countryCode, ignoreType: false)
    }
    var id: Int
    var firstname: String
    var lastname: String
    var fullname: String { firstname + " " + lastname }
    // phone number with natinal format
    var phoneNumber: String
    var imageUrl: URL?
    let chatId: String
}

public class BaseDriver: BaseUser {
    var overallRating: Double!
    var driverRating: Double!
    var carRating: Double!
}

public class BasePassenger: BaseUser {
}
