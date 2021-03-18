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
    
    private var isLocationActive: Bool { SwiftLocation.authorizationStatus == .authorizedWhenInUse || SwiftLocation.authorizationStatus == .authorizedAlways }
    private var loadQueue: DispatchQueue = DispatchQueue(label: "LoadRoutes", qos: .default)
    
    public func loadDirections(for ride: BaseRide, completion: @escaping RouteCompletion) {
        guard isLocationActive else { return }
        DirectionManager
            .shared
            .loadDirections(for: RideDirections(ride: ride))
            .done { response in
                completion(ride, response.routes)
            }
            .catch { _ in
                completion(ride, [])
            }
    }
}
