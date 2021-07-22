//
//  Passenger.swift
//  taxi.Chauffeur
//
//  Created by GG on 21/12/2020.
//

import UIKit
import PhoneNumberKit
import CodableExtension
import Alamofire
import ImageExtension

open class BaseUser: NSObject, Codable {
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
    private enum CodingKeys: String, CodingKey {
            case id, firstname, lastname, phoneNumber, imageUrl, chatId
        }
    
    public var hasValidNumber: Bool {
        return BaseUser.numberKit.isValidPhoneNumber(phoneNumber, withRegion: countryCode, ignoreType: false)
    }
    public var internationalPhone: String {
        guard let internationalCode = BaseUser.numberKit.countryCode(for: countryCode),
            let nummber = try? BaseUser.numberKit.parse("\(internationalCode)\(phoneNumber)") else { return phoneNumber }
        return BaseUser.numberKit.format(nummber, toType: .e164)
    }
    public var id: Int = UUID().uuidString.hash
    public var firstname: String = ""
    public var lastname: String = ""
    public var fullname: String { firstname + " " + lastname }
    // phone number with natinal format
    public var phoneNumber: String = ""
    public var chatId: String = ""
    public var imageUrl: String?
    public var image: UIImage? {
        didSet {
            guard let image = image,
                  let url = try? ImageManager.save(image) else {
                return
            }
            imageUrl = url.absoluteString
        }
    }
    
    public override init() {
    }
    
    required public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            //mandatory
            id = try container.decodeIfPresent(Int.self, forKey: .id) ?? UUID().uuidString.hash
            firstname = try container.decode(String.self, forKey: .firstname)
            lastname = try container.decode(String.self, forKey: .lastname)
            firstname = try container.decode(String.self, forKey: .firstname)
            chatId = try container.decodeIfPresent(String.self, forKey: .chatId) ?? "In4p1PLFmcvZQffWpRpz" // In4p1PLFmcvZQffWpRpz is Julie in FireStore
            imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
            //optional
            // retrieve an internation string ans split it to countryCode and national number
            let internationalNumber: String = try container.decodeIfPresent(String.self, forKey: .phoneNumber) ?? ""
            guard internationalNumber.isEmpty == false else {
                countryCode = Locale.current.regionCode ?? "fr"
                phoneNumber = ""
                return
            }
            guard let number = try? BaseUser.numberKit.parse(internationalNumber) else {
                throw PhoneNumberError.invalidCountryCode
            }
            countryCode = BaseUser.numberKit.mainCountry(forCode: number.countryCode) ?? "fr"
            guard let nb = try? BaseUser.numberKit.parse(internationalNumber) else {
                throw PhoneNumberError.notANumber
            }
            phoneNumber = BaseUser.numberKit.format(nb, toType: .national)
        } catch  {
            throw error
        }
    }
    
    open func encode(to encoder: Encoder) throws {
        do {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(firstname, forKey: .firstname)
            try container.encode(lastname, forKey: .lastname)
            try container.encode(chatId, forKey: .chatId)
            try container.encode(imageUrl, forKey: .imageUrl)
            guard phoneNumber.isEmpty == false else {
                try container.encode(phoneNumber, forKey: .phoneNumber)
                return
            }
            guard let number = try? BaseUser.numberKit.parse(phoneNumber, withRegion: countryCode, ignoreType: false)  else {
                throw PhoneNumberError.invalidCountryCode
            }
            try container.encode(BaseUser.numberKit.format(number, toType: .international), forKey: .phoneNumber)
        } catch  {
            throw error
        }
    }
    
    open var multipartDate: MultipartFormData {
        let data = MultipartFormData()
        try? data.encode(id)
        try? data.encode(firstname)
        try? data.encode(lastname)
        try? data.encode(chatId)
        try? data.encode(phoneNumber)
        if let imageUrl = imageUrl,
           let url = URL(string: imageUrl),
           url.isFileURL,
           let imageData = UIImage(contentsOfFile: imageUrl)?.jpegData(compressionQuality: 0.7) {
            data.append(imageData, withName: "image", fileName: "image", mimeType: "image/jpg")
        }
        return data
    }
}

open class BaseDriver: BaseUser {
    public var overallRating: Double!
    public var driverRating: Double!
    public var carRating: Double!
    
    public static var `default` = BaseDriver()
}

open class BasePassenger: BaseUser {
    public static var `default` = BasePassenger()
}
