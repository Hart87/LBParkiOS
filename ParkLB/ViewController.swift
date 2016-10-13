//
//  ViewController.swift
//  ParkLB
//
//  Created by James Hart on 10/11/16.
//  Copyright © 2016 James Hart. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import AudioToolbox
import Alamofire
import SwiftyJSON


class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UIGestureRecognizerDelegate {
    
    //Outlets
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var segmentedControl: UISegmentedControl!
    
    //Properties
    let locationManager = CLLocationManager()
    let gestureRecognizer = UILongPressGestureRecognizer()
    var alamoLat:String = ""
    var alamoLon:String = ""
    var alamoNote:String = ""
    var alamoTime:String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Status bar
        UIApplication.shared.statusBarStyle = .lightContent

        //mapView
        let location = CLLocationCoordinate2D(
            latitude: 40.585573,
            longitude: -73.697248
        )
        
        let span = MKCoordinateSpanMake(0.2, 0.2)
        let region = MKCoordinateRegion(center: location, span: span)
        
        mapView.setRegion(region, animated: true)
        mapView.showsUserLocation = true
        mapView.showsScale = true
        mapView.showsCompass = true
        mapView.showsTraffic = true
        mapView.delegate = self
        
        // Request for a user's authorization for location services
        locationManager.requestWhenInUseAuthorization()
        let status = CLLocationManager.authorizationStatus()
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            mapView.showsUserLocation = true
        }
        
        //Gesture Recognizer
            //Long Press
            gestureRecognizer.delegate = self
            gestureRecognizer.minimumPressDuration = 1.0
            gestureRecognizer.addTarget(self, action: "handleTap")
            mapView.addGestureRecognizer(gestureRecognizer)
            //Shake
            self.becomeFirstResponder()
        
        
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if(event?.subtype == UIEventSubtype.motionShake) {
            
           RefreshControl()
            
        }
    }
    
    
    
    @IBAction func ChangeMap(_ sender: AnyObject) {
        
        switch (sender.selectedSegmentIndex) {
            
        case 0:
            self.mapView.mapType = MKMapType.standard
            break;
        case 1:
            self.mapView.mapType = MKMapType.satellite
            break;
        case 2:
            self.mapView.mapType = MKMapType.hybridFlyover
            break;
        default:
            break;
        }
        
    }
    
    func RefreshControl() {
        print("Refresh Control")
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))

    }
    
    //Gesture Recognizer Selector
    func handleTap() {
        
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        
        let location = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(location,toCoordinateFrom: mapView)
        print(coordinate.latitude)
        print(coordinate.longitude)
        
        //convert to string for Alamofire
        var latString = String(coordinate.latitude)
        var lonString = String(coordinate.longitude)
        self.alamoLat = latString
        self.alamoLon = lonString

        
        //Create & Display Alert
        let CreateSpotAlert = UIAlertController(title: "Create Parking Spot", message: "Create a parking spot for this location?" , preferredStyle: .alert)
        
        let todaysDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy h:mm a"
        let stringDate = dateFormatter.string(from: todaysDate)
        self.alamoTime = stringDate
        
        CreateSpotAlert.addTextField { (textField : UITextField!) -> Void in
            
            textField.placeholder = "Add a note about this spot"
        }
        
        CreateSpotAlert.addTextField { (textField : UITextField!) -> Void in
            
            textField.text = stringDate
        }
        
        //API ...
        let Yes = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler:{ (action) -> Void in
            let tf1 = (CreateSpotAlert.textFields?[0])! as UITextField
            let tf2 = (CreateSpotAlert.textFields?[1])! as UITextField
            
            // Add Annotation
            let annotation = MKPointAnnotation()
            annotation.title = tf2.text
            annotation.subtitle = tf1.text
            self.alamoNote = tf1.text!
            annotation.coordinate = coordinate
            self.mapView.showAnnotations([annotation], animated: true)
            self.mapView.selectAnnotation(annotation, animated: true)
            
            //Alamofire off of the main thread
            DispatchQueue.global(qos: .background).async {
                
                //Alamofire POST
                
                
            }
            
            
        })
        
        //Cancel Action
        let cancelAction = UIAlertAction(title: "Back", style: UIAlertActionStyle.cancel, handler: nil)
        
        CreateSpotAlert.addAction(Yes)
        CreateSpotAlert.addAction(cancelAction)
        
        self.present(CreateSpotAlert, animated: true, completion: nil)

    }
    
    
    // MARK : CREATE PARKING SPOT
    @IBAction func FindLocationAndCreate(_ sender: AnyObject) {
        
        //Init
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        
        
        //Find Location
        let location = self.locationManager.location
        
        let latitude: Double = location!.coordinate.latitude
        let longitude: Double = location!.coordinate.longitude
        
        //convert to string for Alamofire
        var latString = String(describing: location?.coordinate.latitude)
        let lonString = String(describing: location?.coordinate.longitude)
        self.alamoLat = latString
        self.alamoLon = lonString
        
        print("current latitude :: \(latitude)")
        print("current longitude :: \(longitude)")
        let Spotlocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        //Create & Display Alert
         let CreateSpotAlert = UIAlertController(title: "Create Parking Spot", message: "Create a parking spot for your current location?" , preferredStyle: .alert)
        
        let todaysDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy h:mm a"
        let stringDate = dateFormatter.string(from: todaysDate)
        self.alamoTime = stringDate
        
        CreateSpotAlert.addTextField { (textField : UITextField!) -> Void in
            
            textField.placeholder = "Add a note about this spot"
        }
        
        CreateSpotAlert.addTextField { (textField : UITextField!) -> Void in
            
            textField.text = stringDate
        }
        
        //API ...
        let Yes = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler:{ (action) -> Void in
            let tf1 = (CreateSpotAlert.textFields?[0])! as UITextField
            let tf2 = (CreateSpotAlert.textFields?[1])! as UITextField
            
            // Add Annotation
            let annotation = MKPointAnnotation()
            annotation.title = tf2.text
            annotation.subtitle = tf1.text
            self.alamoNote = tf1.text!
            annotation.coordinate = Spotlocation
            self.mapView.showAnnotations([annotation], animated: true)
            self.mapView.selectAnnotation(annotation, animated: true)
            
            //Alamofire off of the main thread
            DispatchQueue.global(qos: .background).async {
                
                //Alamofire POST
                
                
            }

            
        })
        
        //Cancel Action
        let cancelAction = UIAlertAction(title: "Back", style: UIAlertActionStyle.cancel, handler: nil)
        
        CreateSpotAlert.addAction(Yes)
        CreateSpotAlert.addAction(cancelAction)
        
        self.present(CreateSpotAlert, animated: true, completion: nil)
    
        
    }

    
    
    //Zoom Utitlity
    func zoomToUserLocationInMapView(_ mapView: MKMapView) {
        if let coordinate = mapView.userLocation.location?.coordinate {
            let region = MKCoordinateRegionMakeWithDistance(coordinate, 1200, 1200)
            mapView.setRegion(region, animated: true)
        }
    }
    
    //Zoom button
    @IBAction func Zoom(_ sender: AnyObject) {
        mapView.userTrackingMode = .follow
        zoomToUserLocationInMapView(mapView)
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

