//
//  RideAnnotationView.swift
//  taxi.Chauffeur
//
//  Created by GG on 18/12/2020.
//

import UIKit
import MapKit
import ImageExtension

public class RideAnnotationView: MKAnnotationView {
    public init(annotation: RideAnnotation) {
        super.init(annotation: annotation, reuseIdentifier: "RideAnnotation")
        image = UIImage(named: annotation.isStart ? "startMapIcon" : "endMapIcon", in: .module, with: nil)
        canShowCallout = false
//        centerOffset = CGPoint(x: 0, y: -(image?.size.height ?? 0) / 2.0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
