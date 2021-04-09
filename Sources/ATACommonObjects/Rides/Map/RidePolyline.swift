//
//  RidePolyline.swift
//  taxi.Chauffeur
//
//  Created by GG on 18/12/2020.
//

import UIKit
import MapKit
import ATAConfiguration

public class RidePolyline: MKPolyline {
    public static var configuration: ATAConfiguration!
    public static var approachColor: UIColor?
    public static var rideColor: UIColor?
    public var routeType: Route.RouteType = .approach
    public var color: UIColor {
        switch routeType {
        case .approach: return RidePolyline.approachColor ?? RidePolyline.configuration.palette.inactive
        case .ride: return RidePolyline.rideColor ?? RidePolyline.configuration.palette.primary
        }
    }
    public var lineDashPattern: [NSNumber]? {
        switch routeType {
        case .approach: return [4, 6]
        case .ride: return nil
        }
    }
    
    public var lineWidth: CGFloat {
        switch routeType {
        case .approach: return 2
        case .ride: return 5
        }
    }
    
    public convenience init(points: UnsafePointer<MKMapPoint>, count: Int, routeType: Route.RouteType) {
        self.init(points: points, count: count)
        self.routeType = routeType
    }

    public convenience init(coordinates coords: UnsafePointer<CLLocationCoordinate2D>, count: Int, routeType: Route.RouteType) {
        self.init(coordinates: coords, count: count)
        self.routeType = routeType
    }
}
