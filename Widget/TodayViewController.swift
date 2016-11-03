//
//  TodayViewController.swift
//  Widget
//
//  Created by James Hart on 11/3/16.
//  Copyright © 2016 James Hart. All rights reserved.
//

import UIKit
import NotificationCenter
import Alamofire
import SwiftyJSON


class TodayViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet var numbersLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var activityInd: UIActivityIndicatorView!
    
    struct WidgetPin {
        var note:String = ""
        var time:String = ""
        var latitude:Double = 0.00
        var longitude:Double = 0.00
        
        init(note:String, time:String, latitude:Double, longitude:Double) {
            self.note =  note
            self.time = time
            self.latitude = latitude
            self.longitude = longitude
        }
    }
    
    var pins = [WidgetPin]() //Array of objects from the above struct

    
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.messageLabel.text = "Retrieving info for you 😎"
        activityInd.isHidden = false
        activityInd.startAnimating()
        GetSpots() 
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(_ completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
    func GetSpots() {
        let urlString:String = "http://parklbny87.herokuapp.com/api/spots"
        
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
                    let pinsApp:WidgetPin = WidgetPin(note: note , time: time, latitude: latit, longitude: longit)
                    self.pins.append(pinsApp)
                    print("Items in array: \(self.pins.count)")
                    
                    self.activityInd.isHidden = true
                    self.activityInd.stopAnimating()
                    self.numbersLabel.text = "\(self.pins.count)"
                    self.messageLabel.text = "New parking spots available 😎"
                
        
                }
            }
        }
    } //end GetSpots
}//end Class
