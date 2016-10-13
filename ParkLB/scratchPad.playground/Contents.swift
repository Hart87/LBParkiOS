//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"

let todaysDate = Date()
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
let stringDate = dateFormatter.string(from: todaysDate)