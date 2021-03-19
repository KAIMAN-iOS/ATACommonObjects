//
//  DriverAnnotation.swift
//  taxi.Chauffeur
//
//  Created by GG on 18/12/2020.
//

import UIKit
import MapKit

public class DriverAnnotation: NSObject, MKAnnotation {
    @objc public dynamic var coordinate: CLLocationCoordinate2D
    public let title: String?
    
    public init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        title = nil
    }
}
