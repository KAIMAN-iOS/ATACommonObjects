//
//  RideDirectionManager.swift
//  taxi.Chauffeur
//
//  Created by GG on 22/12/2020.
//

import UIKit
import SwiftLocation
import MapKit
import MapExtension

public enum RideSortCriteria {
    case any, shortestDistance, shortestTime
}

public struct RideDirections: Directions {
    public var id: String { "\(ride.id)" }
    public var directions: [Direction] {
        var dir: [RideDirection] = []
        if let userLocation = SwiftLocation.lastKnownGPSLocation?.coordinate {
            dir.append(RideDirection(id: RideDirection.start, startLocation: userLocation, endLocation: ride.fromAddress.asCoordinates2D))
        }
        if let toAddress = ride.toAddress?.asCoordinates2D {
            dir.append(RideDirection(id: RideDirection.end, startLocation: ride.fromAddress.asCoordinates2D, endLocation: toAddress))
        }
        return dir
    }
    
    var ride: BaseRide!
    public init(ride: BaseRide) {
        self.ride = ride
    }
}

extension DirectionsAnswer {
    public var routes: [Route] {
        directions.compactMap { (key, route) -> Route? in
            Route(routeType: key == RideDirection.start ? .approach : .ride, route: route)
        }
    }
}

public struct RideDirection: Direction {
    fileprivate static let start = "start"
    fileprivate static let end = "end"
    public var id: String
    public var startLocation: CLLocationCoordinate2D
    public var endLocation: CLLocationCoordinate2D
}

public struct Route {
    public enum RouteType {
        case approach, ride
    }
    public var routeType: RouteType!
    public var route: MKRoute?
    public init(routeType: RouteType!, route: MKRoute?) {
        self.routeType = routeType
        self.route = route
    }
}

public class RideDirectionManager {
    public typealias RouteCompletion = ((_ ride: BaseRide, _ routes: [Route]) -> Void)
    public static let shared: RideDirectionManager = RideDirectionManager()
    private var routes: [Ride: [Route]] = [:]
    private init() {}
    private let geoCoder = CLGeocoder()
    
    private var isLocationActive: Bool { SwiftLocation.authorizationStatus == .authorizedWhenInUse || SwiftLocation.authorizationStatus == .authorizedAlways }
    private var loadQueue: DispatchQueue = DispatchQueue(label: "LoadRoutes", qos: .default)
    
    public func loadDirections<T: BaseRide>(for ride: T, sortCriteria: RideSortCriteria = .any, completion: @escaping ((_ ride: T, _ routes: [Route]) -> Void)) {
        guard isLocationActive else { return }
        DirectionManager
            .shared
            .loadDirections(for: RideDirections(ride: ride))
            .done { response in
                var routes = response.routes
                switch sortCriteria {
                case .any: ()
                case .shortestTime: routes.sort(by: { ($0.route?.expectedTravelTime ?? 0) < ($1.route?.expectedTravelTime ?? 0) })
                case .shortestDistance: routes.sort(by: { ($0.route?.distance ?? 0) < ($1.route?.distance ?? 0) })
                }
                completion(ride, routes)
            }
            .catch { _ in
                completion(ride, [])
            }
    }
    
    public func geoCodeAddress(for location: CLLocationCoordinate2D, completion: @escaping ((CLPlacemark?) -> Void)) {
        geoCoder.reverseGeocodeLocation(CLLocation(latitude: location.latitude, longitude: location.longitude)) { placemarks, error in
            guard error == nil,
                  let placemark = placemarks?.first else {
                completion(nil)
                return
            }
            completion(placemark)
        }
    }
}
