//
//  Passenger.swift
//  taxi.Chauffeur
//
//  Created by GG on 21/12/2020.
//

import Foundation
import PhoneNumberKit

public class BaseUser: Codable {
    public static let numberKit = PhoneNumberKit()
    public static let numberFormatter = PhoneNumberFormatter()
    public var phoneFormatter: PartialFormatter  {
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
    
    public var countryCode: String = "FR" {
        didSet {
            BaseUser.numberFormatter.defaultRegion = countryCode
        }
    }
    public var hasValidNumber: Bool {
        return BaseUser.numberKit.isValidPhoneNumber(phoneNumber, withRegion: countryCode, ignoreType: false)
    }
    public var id: Int = UUID().uuidString.hash
    public var firstname: String = ""
    public var lastname: String = ""
    public var fullname: String { firstname + " " + lastname }
    // phone number with natinal format
    public var phoneNumber: String = ""
    public var imageUrl: String?
    public var chatId: String = ""
    
    public init() {
    }
}

public class BaseDriver: BaseUser {
    public var overallRating: Double!
    public var driverRating: Double!
    public var carRating: Double!
    
    public static var `default` = BaseDriver()
}

public class BasePassenger: BaseUser {
    public static var `default` = BasePassenger()
}
