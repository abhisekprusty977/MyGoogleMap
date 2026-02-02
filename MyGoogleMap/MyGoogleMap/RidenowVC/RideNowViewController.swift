//
//  RideNowViewController.swift
//  MyGoogleMap
//
//  Created by Abhisek Prusty on 24/02/23.
//

import UIKit
import CoreLocation
import GoogleMaps
import GooglePlaces

class RideNowViewController: UIViewController {
    @IBOutlet var txt_pick: UITextField!
    @IBOutlet var txt_drop: UITextField!
    @IBOutlet var lbl_totaldistance: UILabel!
    @IBOutlet var lbl_totaltime: UILabel!
    @IBOutlet var lbl_totalfare: UILabel!
    @IBOutlet var mapview: GMSMapView!
    
    var picSource: CLLocationCoordinate2D?
    var dropDestination: CLLocationCoordinate2D?
    var sourceStr: String?
    var destinationStr: String?
    var path = GMSPath()
    var timerRoute : Timer?
    var animationPolyline = GMSPolyline()
    var animationPath = GMSMutablePath()
    var i: UInt = 0
    var bounds = GMSCoordinateBounds()
    var gms_Api_key = "AIzaSyDZqLuEcKIxjZ9T-OQ1bVnwEmTPBmYl9EU"
    var carMarker = GMSMarker()
    var carMovement = ARCarMovement()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        myRideDisplay()
       
    }
    override func viewWillAppear(_ animated: Bool) {
        //self.navigationController?.navigationBar.isHidden = true
        navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.backgroundColor = .none
        self.navigationController?.barHideOnSwipeGestureRecognizer.isEnabled = true
        self.navigationController?.navigationBar.tintColor = UIColor.blue
    }
    
    
    func myRideDisplay(){
        if picSource != nil && dropDestination != nil{
            movementOfcar()
            self.txt_pick.text = sourceStr!
            self.txt_drop.text = destinationStr!
            
            CATransaction.begin()
            CATransaction.setValue(1.5, forKey: kCATransactionAnimationDuration)
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: (self.picSource?.latitude)!, longitude: (self.picSource?.longitude )!)
            marker.map = self.mapview
            marker.icon = UIImage(named: "picloc1")
            
            self.bounds = self.bounds.includingCoordinate(marker.position)
            CATransaction.commit()
            
            
            do {
                getPolylineRoute(from: picSource!, to: dropDestination!)
            }
        }
        
    }
    
    func getPolylineRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D){
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        let origin1 = "\(source.latitude),\(source.longitude)"
        let destination1 = "\(destination.latitude),\(destination.longitude)"
        
        let url = URL(string: "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin1)&destination=\(destination1)&mode=driving&key=\(gms_Api_key)")!
        
        let task = session.dataTask(with: url, completionHandler: {
            (data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
            }
            else
            {
                do {
                    if let json : [String:Any] = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any]{
                        let jsonDict = CEnumObj.shareInstance.convertToJSON(resulTDict: json as NSDictionary)
                        let status = jsonDict.object(forKey: "status") as! String
                        print("status=",status)
                        if status == "ZERO_RESULTS"{
                            DispatchQueue.main.async {
                                let alerts = UIAlertController(title: NSLocalizedString("dropLocText", comment: ""), message: NSLocalizedString("chooseAnotherLoc", comment: ""), preferredStyle: .alert)
                                let ok = UIAlertAction(title: "OK", style: .default, handler: {
                                    (alert) in
                                    self.dismiss(animated: true, completion: nil)
                                })
                                alerts.addAction(ok)
                                self.present(alerts, animated: true, completion: nil)
                                
                            }
                        }
                        else
                        {
                            let routeArr = json["routes"] as? [Any]
                            let jsonRouteArr = jsonDict.object(forKey: "routes") as! NSArray
                            print("jsonRouteArr=",jsonRouteArr)
                            let legsArr = jsonRouteArr.value(forKey: "legs") as! NSArray
                            let distanceDict = legsArr.value(forKey: "distance") as? NSArray
                            let distanceText = (distanceDict![0] as AnyObject).value(forKey: "text") as!NSArray
                            let distance = distanceText[0] as! String
                            let durationDict = legsArr.value(forKey: "duration") as? NSArray
                            let timeText = (durationDict![0] as AnyObject).value(forKey: "text") as!NSArray
                            
                            let timeStr = timeText[0] as! String
                            
                            let dict = routeArr![0] as! NSDictionary
                            let dictOverFlow = dict["overview_polyline"] as! NSDictionary
                            let points = dictOverFlow["points"] as! String
                            DispatchQueue.main.async {
                                self.lbl_totaltime.text = timeStr
                                self.lbl_totaldistance.text = distance
                                self.showPaths(polyStr: points, dropLoc:self.dropDestination!)
                            }
                        }
                    }
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        })
        task.resume()
    }
    
    func showPaths(polyStr :String, dropLoc: CLLocationCoordinate2D)
    {
        let tDistance = (CLLocation(latitude: (self.picSource?.latitude)!, longitude: (self.picSource?.longitude)!)).distance(from: CLLocation(latitude: dropLoc.latitude, longitude: dropLoc.longitude))
        let price = 1 * tDistance/1000
        let priceStr = String(format: "%.2f", price)
        self.lbl_totalfare.text = "$\(priceStr)"
        
        self.path = GMSPath(fromEncodedPath: polyStr)!
        let polyline = GMSPolyline(path: self.path)
        polyline.strokeWidth = 5.0
        polyline.strokeColor = UIColor.lightGray
        polyline.map = self.mapview
        
        CATransaction.begin()
        CATransaction.setValue(1.5, forKey: kCATransactionAnimationDuration)
        let lat = dropLoc.latitude
        let long = dropLoc.longitude
        
        let destmarker = GMSMarker()
        destmarker.position = CLLocationCoordinate2D(latitude: lat, longitude: long)
        destmarker.map = self.mapview
        
        destmarker.icon = UIImage(named: "droploc1")
        self.bounds = self.bounds.includingCoordinate(destmarker.position)
        let update = GMSCameraUpdate.fit(self.bounds, withPadding: 50)
        self.mapview.animate(with: update)
        CATransaction.commit()
        
        
        self.timerRoute = Timer.scheduledTimer(withTimeInterval: 0.009, repeats: true, block: {
            (timers) in
            if self.i < (self.path.count()) {
                self.animationPath.add(self.path.coordinate(at: self.i))
                self.animationPolyline.path = self.animationPath
                
                self.animationPolyline.strokeColor = UIColor(red: 20/255, green: 154/255, blue: 214/255, alpha: 1)
                self.animationPolyline.strokeWidth = 5.0
                self.animationPolyline.map = self.mapview
                self.i += 1
            }
            else {
                self.i = 0
                self.animationPath = GMSMutablePath()
                self.animationPolyline.map = nil
            }
            
        })
    }
    
    func movementOfcar() {
        carMarker.icon = UIImage(named: "movecar")
        carMovement.arCarMovement(marker: carMarker, oldCoordinate: picSource!, newCoordinate: picSource!, mapView: mapview)
    }
    
    
    //MARK: - BUTTON ACTION
    
    @IBAction func Confirm_Booking(_ sender: UIButton) {
        self.carMovement.arCarMovement(marker: carMarker, oldCoordinate: picSource!, newCoordinate: dropDestination!, mapView: self.mapview, bearing: 0.0)
    }
    
}
