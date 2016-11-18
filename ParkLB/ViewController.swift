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
import GoogleMobileAds
import Social
import MessageUI


class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UIGestureRecognizerDelegate,MFMessageComposeViewControllerDelegate {
    
    //Outlets
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var bannerView: GADBannerView!
    
    // GIT Clone Test
    
    //Properties
    var currentPlacemark:CLPlacemark?
    let locationManager = CLLocationManager()
    let gestureRecognizer = UILongPressGestureRecognizer()
    var alamoLat:String = ""
    var alamoLon:String = ""
    var alamoNote:String = ""
    var alamoTime:String = ""
    var pins = [Pin]() //Array for annotations from object (Pin.swift)
    var addressString:String = "empty"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Retrieve and plot spots
        GetSpots()
    
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
        
        //Google AdMob
        print("*******Google Mobile Ads SDK version: \(GADRequest.sdkVersion())********")
        bannerView.adUnitID = "ca-app-pub-3278937459625561/1724589732"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        
        
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if(event?.subtype == UIEventSubtype.motionShake) {
            
           //Delete Annotations to clear map
            let allAnnotations = self.mapView.annotations
            self.mapView.removeAnnotations(allAnnotations)
            mapView.removeOverlays(mapView.overlays)
            
           //Retrieve spot information and plot annotations
           GetSpots()
            
        }
    }
    
    
    @IBAction func RefreshButton(_ sender: AnyObject) {
        
        //Delete Annotations to clear map
        let allAnnotations = self.mapView.annotations
        self.mapView.removeAnnotations(allAnnotations)
        mapView.removeOverlays(mapView.overlays)
        
        //Retrieve spot information and plot annotations
        GetSpots()
        
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
    
    func GetSpots() {
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        var urlString:String = "http://parklbny87.herokuapp.com/api/spots"
        
        //Alamofire GET
        Alamofire.request(urlString).responseJSON { response in
            print(response.result.value)
            
            //parse JSON
            if let JSONresp = response.result.value {
                
                let json = JSON(JSONresp)
                
                for pinResp in json.array! {
                    
                    let note: String = pinResp["note"].stringValue
                    let time: String = pinResp["time"].stringValue
                    let latit: Double = pinResp["latitude"].doubleValue
                    let longit: Double = pinResp["longitude"].doubleValue
                    
                    //Array Time
                    var pinsApp:Pin = Pin(note: note , time: time, latitude: latit, longitude: longit)
                    self.pins.append(pinsApp)
                    print("Items in array: \(self.pins.count)")
                    
                    //Plot Annotations
                    let annotation = MKPointAnnotation()
                    annotation.title = pinsApp.time
                    annotation.subtitle = pinsApp.note
                    let Spotlocation = CLLocationCoordinate2D(latitude: pinsApp.latitude, longitude: pinsApp.longitude)
                    annotation.coordinate = Spotlocation
                    self.mapView.showAnnotations([annotation], animated: true)
                    self.mapView.selectAnnotation(annotation, animated: true)
                    
                } // end for loop
                
                //Center the mapView onto the users location
                self.zoomToUserLocationInMapView(self.mapView)
            }
        }
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
                let postEndpoint:String = "http://parklbny87.herokuapp.com/api/spots"
                
                //Check these names - just markups
                let params: [String:Any]? = [
                    "spot": [
                        "note": self.alamoNote,
                        "time": self.alamoTime,
                        "latitude" : self.alamoLat,
                        "longitude" : self.alamoLon
                    ]
                ]
                
                
                Alamofire.request(postEndpoint, method: .post, parameters: params).response { response in
                    debugPrint(response)
                    
                } // end POST request
            } // end background thread
            
            
        }) // end Yes action for alert
        
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
        let latString = String(location!.coordinate.latitude)
        let lonString = String(location!.coordinate.longitude)
        self.alamoLat = latString
        self.alamoLon = lonString
        
        print(self.alamoLat)
        print(self.alamoLon)
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
                let postEndpoint:String = "http://parklbny87.herokuapp.com/api/spots"
                
                //Check these names - just markups
                let params: [String:Any]? = [
                    "spot": [
                        "note": self.alamoNote,
                        "time": self.alamoTime,
                        "latitude" : self.alamoLat,
                        "longitude" : self.alamoLon
                    ]
                ]
                
                Alamofire.request(postEndpoint, method: .post, parameters: params).response { response in
                    print(response.response)
                    print(response.data)
                    print(response.request)
                    
                } // end POST request
            }// end background threat
            
        }) // end YES action for alert
        
        //Cancel Action
        let cancelAction = UIAlertAction(title: "Back", style: UIAlertActionStyle.cancel, handler: nil)
        
        CreateSpotAlert.addAction(Yes)
        CreateSpotAlert.addAction(cancelAction)
        
        self.present(CreateSpotAlert, animated: true, completion: nil)
    
        
    }
    
    //Annotation extras
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) ->
        MKAnnotationView? {
            let identifier = "MyPin"
            if annotation.isKind(of: MKUserLocation.self) {
                return nil
            }
            // Reuse the annotation if possible
            var annotationView:MKAnnotationView? =
                mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as?
            MKPinAnnotationView
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation,
                                                     reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                //annotationView?.pinTintColor = UIColor.blue
                annotationView!.image = UIImage(named: "pinicon.png")
            }
            
            //Left iconView
            let leftIconView = UIImageView(frame: CGRect.init(x: 0, y: 0, width: 53, height: 53))
            leftIconView.image = UIImage(named: "liview.png")
            annotationView?.leftCalloutAccessoryView = leftIconView

            //Right callout button
            let btn = UIButton(type: .infoDark)
            annotationView?.rightCalloutAccessoryView = btn
            
            return annotationView
    }
    
    //Get directions for pin callout button
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        let optionsMenu = UIAlertController(title: "Options", message: "What would you like to do?", preferredStyle: .actionSheet)
        
        //Get Directions ...
        let directions = UIAlertAction(title: "Directions", style: UIAlertActionStyle.default, handler:{ (action) -> Void in
            
            //Remove previous overlay before starting
            mapView.removeOverlays(mapView.overlays)
            
            let directionRequest = MKDirectionsRequest()
            
            directionRequest.source = MKMapItem.forCurrentLocation()
            
            //
            let selectedLoc = view.annotation
            let selectedCoord = selectedLoc!.coordinate
            let destinationPlacemark = MKPlacemark(coordinate: selectedCoord)
            directionRequest.destination = MKMapItem(placemark: destinationPlacemark)
            directionRequest.transportType = .automobile
            
            //Calculate directions
            let directions = MKDirections(request: directionRequest)
            
            directions.calculate { (routeResponse, routeError) -> Void in
                
                guard let routeResponse =  routeResponse else {
                    if let routeError = routeError {
                        print("error: \(routeError)")
                    }
                    
                    return
                }
                
                let route = routeResponse.routes[0]
                self.mapView.add(route.polyline, level: MKOverlayLevel.aboveRoads)
                let rect = route.polyline.boundingMapRect
                self.mapView.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
            }
            
            
        })
        
        //Text Address
        let textAction = UIAlertAction(title: "Text Address", style: UIAlertActionStyle.default, handler: {(action) -> Void in
            
            //reverse geocode address
            let selectedLoc = view.annotation
            let lat = selectedLoc?.coordinate.latitude
            let long = selectedLoc?.coordinate.longitude
            let cll = CLLocation(latitude: lat!, longitude: long!)
            
            CLGeocoder().reverseGeocodeLocation(cll, completionHandler: {(placemarks, error) -> Void in
                
                if error != nil {
                    print("Reverse geocoder failed with error" + (error?.localizedDescription)!)
                    return
                }
                
                if (placemarks?.count)! > 0 {
                    let pm = placemarks![0] as! CLPlacemark
                    self.displayLocationInfo(placemark: pm)
                }
                else {
                    print("Problem with the data received from geocoder")
                }
                
                //Text the info...
                if !MFMessageComposeViewController.canSendText(){
                    let alertMessage2 = UIAlertController(title: "SMS Unavailable", message: "Your device is not capable of sending SMS", preferredStyle: .alert)
                    alertMessage2.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alertMessage2, animated: true, completion: nil)
                    return
                    
                }else{
                    
                    //Prefill the SMS
                    let messageController = MFMessageComposeViewController()
                    messageController.messageComposeDelegate = self
                    //messageController.recipients = ["(908)917-2127"]
                    messageController.body = "Parking space available @ \(self.addressString)"
                    
                    self.present(messageController, animated: true, completion: nil)
                    
                }

                
            })

            
            
        })
        
        //Cancel Action
        let cancelAction = UIAlertAction(title: "OK", style: .cancel) { (action) in
        }
        
        optionsMenu.addAction(directions)
        optionsMenu.addAction(textAction)
        optionsMenu.addAction(cancelAction)
        
        self.present(optionsMenu, animated: true, completion: nil)

        
    }
    
    func displayLocationInfo(placemark: CLPlacemark){
        
        self.locationManager.stopUpdatingLocation()
        
        let  subthor = placemark.subThoroughfare!
        let throughfare = placemark.thoroughfare!
        let locality = placemark.locality!
        let adminArea = placemark.administrativeArea!
        let postalCode = placemark.postalCode!
        //var country = placemark.country
        
        let userLocation = "\(subthor) \(throughfare) \(locality) \(adminArea) \(postalCode)"
        self.addressString = userLocation
        
    }
    
    
    //Draw the directions on the map
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.green
        renderer.lineWidth = 4.0
        
        return renderer
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
    
    
    @IBAction func Directions(_ sender: AnyObject) {
        
        //Create & Display Alert
        let directionsAlert = UIAlertController(title: "Directions 😎", message: "Press & hold down anywhere on the map to create a parking spot there. \n \n" + "Press the + button to create a parking spot where you are \n \n" + "Shake the phone or press the refresh button to get the latest parking spots \n \n" + "Press the magnifying glass to zoom into your location, the map will scroll as you move and follow you \n \n" + "Tell your friends! : The more people that use this the more efficient the service becomes" , preferredStyle: .alert)
        
        //Cancel Action
        let dismissAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.cancel, handler: nil)
        
        directionsAlert.addAction(dismissAction)
        
        
        self.present(directionsAlert, animated: true, completion: nil)

    }
    
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {
        switch(result) {
        
        case MessageComposeResult.cancelled:
            print("SMS cancelled")
        
        case MessageComposeResult.failed:
            let alertMessage = UIAlertController(title: "Failure", message: "Failed to send the message.", preferredStyle: .alert)
                alertMessage.addAction(UIAlertAction(title: "OK", style: .default,
                                                     handler: nil))
                present(alertMessage, animated: true, completion: nil)
        
        case MessageComposeResult.sent:
            print("SMS sent")
        
        }
        
        dismiss(animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

