//
//  RideAnnotation.swift
//  taxi.Chauffeur
//
//  Created by GG on 18/12/2020.
//

import UIKit
import MapKit
import ATAConfiguration

public class RideAnnotation: NSObject, MKAnnotation {
    public static var configuration: ATAConfiguration!
    public var isStart: Bool = true
    public let coordinate: CLLocationCoordinate2D
    public let title: String?
    
    public var tintColor: UIColor {
        isStart ? RideAnnotation.configuration.palette.confirmation : RideAnnotation.configuration.palette.primary
    }
    
    public init(address: Address, isStart: Bool = true) {
        self.isStart = isStart
        coordinate = address.asCoordinates2D
        title = address.address
    }
    
    public init(coordinates: CLLocationCoordinate2D, isStart: Bool = true) {
        coordinate = coordinates
        title = nil
        self.isStart = isStart
    }
}
