//
//  ViewController.swift
//  MyGoogleMap
//
//  Created by Abhisek Prusty on 23/02/23.
//

import UIKit
import GoogleMaps
import GooglePlaces

class ViewController: UIViewController,CLLocationManagerDelegate,UITextFieldDelegate, GMSMapViewDelegate, GMSAutocompleteViewControllerDelegate {
    @IBOutlet var view_pick: UIView!
    @IBOutlet var view_drop: UIView!
    
    @IBOutlet var txt_pickup: UITextField!
    @IBOutlet var txt_drop: UITextField!
    
    @IBOutlet var lbl_green: UILabel!
    @IBOutlet var lbl_red: UILabel!
    
    @IBOutlet var img_centermapicon: UIImageView!
    
    @IBOutlet var mapView: GMSMapView!
    
    var picLocation: CLLocationCoordinate2D?
    var dropLocation: CLLocationCoordinate2D?
    
    var isGesturePic = true
    var isAutoCompleCall = false
    
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeAuthentication()
        self.mapView.delegate = self
        
        view_drop.layer.opacity = 0.5
        view_pick.layer.opacity = 1.0
        
        txt_pickup.delegate = self
        txt_drop.delegate = self
        txt_pickup.addTarget(self, action: #selector(picLocationPressed), for: .touchDown)
        txt_drop.addTarget(self, action: #selector(dropLocationpressed), for: .touchDown)
        
    }
    
    func initializeAuthentication(){
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
    }
    @objc func picLocationPressed()
    {
        isGesturePic = true
        isAutoCompleCall = true
        img_centermapicon.image = UIImage(named: "picloc1")
        if view_pick.layer.opacity == 0.5 {
            view_drop.layer.opacity = 0.5
            view_pick.layer.opacity = 1.0
            DispatchQueue.main.async {
                CATransaction.begin()
                CATransaction.setValue(1.5, forKey: kCATransactionAnimationDuration)
                let camera = GMSCameraPosition.camera(withLatitude: (self.picLocation?.latitude)!, longitude: (self.picLocation?.longitude)!, zoom: 18)
                self.mapView.camera = camera
                CATransaction.setCompletionBlock{
                self.mapView.animate(to: camera)
                }
                CATransaction.commit()
            }
        }
        else
        {
            view_pick.layer.opacity = 1.0
            let autoCompleteVC = GMSAutocompleteViewController()
            autoCompleteVC.delegate = self
            let addressFilter = GMSAutocompleteFilter()
            //addressFilter.type = .noFilter
            addressFilter.types = []
            autoCompleteVC.autocompleteFilter = addressFilter
            present(autoCompleteVC, animated: true, completion: nil)
        }
    }
    @objc func dropLocationpressed()
    {
        isGesturePic = false
        isAutoCompleCall = true
        img_centermapicon.image = UIImage(named: "droploc1")
        if view_drop.layer.opacity == 0.5 {
            view_pick.layer.opacity = 0.5
            view_drop.layer.opacity = 1.0
            if self.dropLocation != nil {
            DispatchQueue.main.async {
                CATransaction.begin()
                CATransaction.setValue(1.5, forKey: kCATransactionAnimationDuration)
                let camera = GMSCameraPosition.camera(withLatitude: (self.dropLocation?.latitude)!, longitude: (self.dropLocation?.longitude)!, zoom: 18)
                self.mapView.camera = camera
                CATransaction.setCompletionBlock{
                self.mapView.animate(to: camera)
                }
                CATransaction.commit()
            }
        }
        }
        else
        {
            let autoCompleteVC = GMSAutocompleteViewController()
            autoCompleteVC.delegate = self
            let addressFilter = GMSAutocompleteFilter()
            //addressFilter.type = .noFilter
            addressFilter.types = []
            autoCompleteVC.autocompleteFilter = addressFilter
            present(autoCompleteVC, animated: true, completion: nil)
        }
    }
    
    @objc func handleTheGesture(gesture: UIScreenEdgePanGestureRecognizer)
    {
        print("state!!=",gesture.state)
    }
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == txt_drop{
            txt_drop.resignFirstResponder()
        }
        else
        {
            txt_pickup.resignFirstResponder()
        }
        return false
    }
    
    func draggedToMaponLoc(location: CLLocationCoordinate2D, isPic: Bool)
    {
        if isPic{
            img_centermapicon.image = UIImage(named: "picloc1")
            //pick
        }
        else
        {
            img_centermapicon.image = UIImage(named: "droploc1")
            //drop
        }
        let camera = GMSCameraPosition.camera(withLatitude: location.latitude, longitude: location.longitude, zoom: 18)
        self.mapView.camera = camera
        self.mapView.animate(to: camera)
    }
    
    func getlocalAddress(location: CLLocationCoordinate2D, textField: UITextField)
    {
        let geocoder = GMSGeocoder()
        geocoder.reverseGeocodeCoordinate(location) {response, error in
            if error == nil
            {
                if let places = response?.results()
                {
                    if let place = places.first
                    {
                        if let line = place.lines
                        {
                            let strArr = line.first?.components(separatedBy: ",")
                            textField.text = "\(strArr![0]), \(strArr![1])"
                        }
                    }
                }
            }
        }
    }
    
    //MARK: CLLocationManagerDelegate ----------------------
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.mapView.isMyLocationEnabled = true
        let location = locations.last
        picLocation = CLLocationCoordinate2D(latitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!)
        draggedToMaponLoc(location: picLocation!, isPic: true)
        getlocalAddress(location: picLocation!, textField: txt_pickup)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
  
    //MARK: GMSMapViewDelegate ---------------------------
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        if !(isAutoCompleCall){
            switch isGesturePic{
            case true:
                picLocation = position.target
                draggedToMaponLoc(location: picLocation!, isPic: true)
                getlocalAddress(location: picLocation!, textField: txt_pickup)
                break
                
            case false:
                dropLocation = position.target
                draggedToMaponLoc(location: dropLocation!, isPic: true)
                getlocalAddress(location: dropLocation!, textField: txt_drop)
            }
        }
    }
    
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        print("gesture=\(gesture)")
        if gesture {
            isAutoCompleCall = false
            if isGesturePic {
                txt_pickup.text = "Pic location is searching..."
            }
            else {
                txt_drop.text = "Drop location is searching..."
            }
        }
    }
    
    //MARK: GMSAutocompleteViewControllerDelegate ------------------------
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        print("cancel")
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        if isGesturePic {
            picLocation = CLLocationCoordinate2D(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
            draggedToMaponLoc(location: picLocation!, isPic: true)
        }
        else
        {
            dropLocation = CLLocationCoordinate2D(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
            draggedToMaponLoc(location: dropLocation!, isPic: false)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print(error.localizedDescription)
       // dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didSelect prediction: GMSAutocompletePrediction) -> Bool {
        print("prediction.attributedPrimaryText\(prediction.attributedPrimaryText)")
        if isGesturePic
        {
            print("prediction.attributedPrimaryText\(prediction.attributedPrimaryText)")
            txt_pickup.attributedText = prediction.attributedPrimaryText
        }
        else
        {
            txt_drop.attributedText = prediction.attributedPrimaryText
        }
        return true
    }
    
    @IBAction func RIDENOW(_ sender: UIButton) {
        
        if (picLocation != nil) && (dropLocation != nil) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "RideNowViewController") as! RideNowViewController
            vc.picSource = picLocation
            vc.dropDestination = dropLocation
            vc.sourceStr = txt_pickup.text
            vc.destinationStr = txt_drop.text
            self.navigationController?.pushViewController(vc, animated: true)
        }
        else
        {
            print("select your location!")
        }
    }
}

