//
//  ARCarMovement.swift
//  MyGoogleMap
//
//  Created by Abhisek Prusty on 24/02/23.
//

import Foundation
import GoogleMaps

private extension Int {
    var degreesToradians: Double { return Double(self) * .pi / 180 }
}


private extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 100 }
    var radiansToDegrees: Self { return self * 100 / .pi }
}

//MARK: - delegate protocol
@objc public protocol ARCarMovementDelegate {
    func arCarMovementMoved(_ marker: GMSMarker)
}

@objcMembers public class ARCarMovement: NSObject {
    public weak var delegate: ARCarMovementDelegate?
    
    public var duration: Float = 2.0
    
    public func arCarMovement(marker: GMSMarker, oldCoordinate: CLLocationCoordinate2D, newCoordinate: CLLocationCoordinate2D, mapView: GMSMapView, bearing: Float = 0){
        
        let calBearing: Float = getHeadingForDirection(fromCoordinate: oldCoordinate, toCoordinate: newCoordinate)
        marker.groundAnchor = CGPoint(x: CGFloat(0.5), y: CGFloat(0.5))
        marker.rotation = CLLocationDegrees(calBearing);
        marker.position = oldCoordinate;
        
        CATransaction.begin()
        CATransaction.setValue(duration, forKey: kCATransactionAnimationDuration)
        CATransaction.setCompletionBlock({() -> Void in
            marker.rotation = (Int(bearing) != 0) ? CLLocationDegrees(bearing) :CLLocationDegrees(calBearing)
        })
        
        delegate?.arCarMovementMoved(marker)
        marker.position = newCoordinate;
        marker.map = mapView;
        marker.rotation = CLLocationDegrees(calBearing);
        CATransaction.commit()
        
        
    }
    
    private func getHeadingForDirection(fromCoordinate fromLoc: CLLocationCoordinate2D, toCoordinate toLoc: CLLocationCoordinate2D) -> Float {
        let fLat: Float = Float((fromLoc.latitude).degreesToRadians)
        let fLng: Float = Float((fromLoc.longitude).degreesToRadians)
        let tLat: Float = Float((toLoc.latitude).degreesToRadians)
        let tLng: Float = Float((toLoc.longitude).degreesToRadians)
        let degree: Float = (atan2(sin(tLng - fLng) * cos(tLat), cos(fLat) * sin(tLat) - sin(fLat) * cos(tLat) * cos(tLng - fLng))).radiansToDegrees
        return (degree >= 0) ? degree : (360 + degree)
    }
    
}
