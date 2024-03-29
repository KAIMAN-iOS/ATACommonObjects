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
import Combine

open class BaseUser: NSObject, Codable {
    public static let numberKit = PhoneNumberKit()
    public static let numberFormatter = PhoneNumberFormatter()
    public var phoneFormatter: PartialFormatter  {
        let formatter = PartialFormatter()
        formatter.defaultRegion = countryCode
        return formatter
    }
    
//    public var formartedNumber: String? {
//        return BaseUser.numberFormatter.string(for: number)
//    }
//    
//    public var number: PhoneNumber? {
//        return try? BaseUser.numberKit.parse(phoneNumber)
//    }
    
    public var countryCode: String = "FR" {
        didSet {
            BaseUser.numberFormatter.defaultRegion = countryCode
        }
    }
    private enum CodingKeys: String, CodingKey {
            case id, firstname, lastname, phoneNumber, imageUrl, chatId, imageURL, image, countryCode, firebaseToken
        }
    
    public var hasValidNumber: Bool {
        return BaseUser.numberKit.isValidPhoneNumber(phoneNumber, withRegion: countryCode, ignoreType: false)
    }
    public var internationalPhone: String {
        guard let internationalCode = BaseUser.numberKit.countryCode(for: countryCode),
            let nummber = try? BaseUser.numberKit.parse("+\(internationalCode)\(phoneNumber)") else { return phoneNumber }
        return BaseUser.numberKit.format(nummber, toType: .e164)
    }
    public var id: Int = UUID().uuidString.hash
    public var firstname: String = ""
    public var lastname: String = ""
    public var fullname: String { firstname + " " + lastname }
    // phone number with national format
    public var phoneNumber: String = ""
    public var chatId: String = ""
    public var displayName: String { firstname + " " + lastname }
    public var shortDisplayName: String { firstname + " " + "\(lastname.first?.uppercased() ?? "")" + "." }
    public var imageUrl: String?
    public var picture: CurrentValueSubject<UIImage?, Never> = CurrentValueSubject<UIImage?, Never>(nil)
    public var image: UIImage? {
        didSet {
            guard let image = image,
                  let url = try? ImageManager.save(image) else {
                return
            }
            imageUrl = url.absoluteString
            let _ = try? ImageManager.save(image, imagePath: "user-\(id)")
        }
    }
    public var firebaseToken: String?
    /// is set to true, all objects will check if the phone is valid. Otherwise, it will use a blank number instead
    public static var checkPhone: Bool = true
    
    public override init() {
    }
    
    required public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            //mandatory
            let identifier = try container.decodeIfPresent(Int.self, forKey: .id) ?? UUID().uuidString.hash
            id = identifier
            self.image = ImageManager.fetchImage(with: "user-\(identifier)")
            firstname = try container.decode(String.self, forKey: .firstname)
            lastname = try container.decode(String.self, forKey: .lastname)
            firstname = try container.decode(String.self, forKey: .firstname)
            chatId = try container.decodeIfPresent(String.self, forKey: .chatId) ?? "" //"In4p1PLFmcvZQffWpRpz" // In4p1PLFmcvZQffWpRpz is Julie in FireStore
            if let url = try? container.decodeIfPresent(String.self, forKey: .imageUrl) {
                imageUrl = url
            } else if let url = try? container.decodeIfPresent(String.self, forKey: .imageURL) {
                imageUrl = url
            } else if let url = try? container.decodeIfPresent(String.self, forKey: .image) {
                imageUrl = url
            } else {
                imageUrl = nil
            }
            super.init()
            //optional
            // retrieve an internation string ans split it to countryCode and national number
            try extractNumber(from: container)
            handleUserPicture()
            firebaseToken = try container.decodeIfPresent(String.self, forKey: .firebaseToken)
        } catch  {
            throw error
        }
    }
    
    private func extractNumber(from container: KeyedDecodingContainer<BaseUser.CodingKeys>) throws {
        let internationalNumber: String = try container.decodeIfPresent(String.self, forKey: .phoneNumber) ?? ""
        guard internationalNumber.isEmpty == false else {
            countryCode = Locale.current.regionCode ?? "fr"
            phoneNumber = ""
            handleUserPicture()
            return
        }
        
        countryCode = try container.decodeIfPresent(String.self, forKey: .countryCode) ?? (Locale.current.regionCode ?? "FR")
        // try to parse it as it is
        var nb = try? BaseUser.numberKit.parse(internationalNumber)
        if let nb {
            phoneNumber = BaseUser.numberKit.format(nb, toType: .national)
            return
        }
        let code = BaseUser.numberKit.countryCode(for: countryCode) ?? 33
        nb = try? BaseUser.numberKit.parse("\(code)\(internationalNumber)")
        if let nb {
            phoneNumber = BaseUser.numberKit.format(nb, toType: .national)
            return
        }
        nb = try? BaseUser.numberKit.parse("+\(internationalNumber)")
        if let nb {
            phoneNumber = BaseUser.numberKit.format(nb, toType: .national)
            return
        }
        nb = try? BaseUser.numberKit.parse("+\(code)\(internationalNumber)")
        if let nb {
            phoneNumber = BaseUser.numberKit.format(nb, toType: .national)
            return
        }
        if BaseUser.checkPhone {
            throw PhoneNumberError.invalidNumber
        } else {
            phoneNumber = nb == nil ? "" : BaseUser.numberKit.format(nb!, toType: .national)
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
            try container.encodeIfPresent(firebaseToken, forKey: .firebaseToken)
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
        try? data.encode(firebaseToken)
        if let imageUrl = imageUrl,
           let url = URL(string: imageUrl),
           url.isFileURL,
           let imageData = UIImage(contentsOfFile: imageUrl)?.jpegData(compressionQuality: 0.7) {
            data.append(imageData, withName: "image", fileName: "image", mimeType: "image/jpg")
        }
        return data
    }
    
    func handleUserPicture() {
        if let image = self.image {
            picture.send(image)
        }
        
        DispatchQueue.global().async { [weak self] in
            if let self = self,
               let url = self.imageUrl,
               let imgUrl = URL(string: url),
               let data = try? Data(contentsOf: imgUrl),
               let image = UIImage(data: data) {
                self.picture.send(image)
                let _ = try? ImageManager.save(image, imagePath: "user-\(self.id)")
            }
        }
    }
}

open class BaseDriver: BaseUser {
    public var overallRating: Double!
    public var driverRating: Double!
    public var carRating: Double!
    public static var `default` = BaseDriver()
    
    enum CodingKeys: String, CodingKey {
        case overallRating
        case driverRating
        case carRating
    }
    
    public override init() {
        super.init()
    }
    
    required public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            overallRating = try container.decodeIfPresent(Double.self, forKey: .overallRating) ?? 0.0
            driverRating = try container.decodeIfPresent(Double.self, forKey: .driverRating) ?? 0.0
            carRating = try container.decodeIfPresent(Double.self, forKey: .carRating) ?? 0.0
            try super.init(from: decoder)
        } catch(let error)  {
            //os_log("⛔️ 🚕 driver decompress error %@", log: OSLog.mappingObject, type: .error, error.localizedDescription)
            print("🚖 driver decompress error \(error)")
            throw error
        }
    }
}

open class BasePassenger: BaseUser {
    public static var `default` = BasePassenger()
}
