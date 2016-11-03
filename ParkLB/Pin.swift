//
//  Pin.swift
//  ParkLB
//
//  Created by James Hart on 10/14/16.
//  Copyright © 2016 James Hart. All rights reserved.
//

import Foundation

public class Pin {
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
