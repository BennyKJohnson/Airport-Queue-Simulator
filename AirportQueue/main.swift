//
//  main.swift
//  AirportQueue
//
//  Created by Benjamin Johnson on 10/09/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation

// Delay helper function, call block (code) after a period (seconds)

func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), closure)
}


let location = "ass2data.txt"

let airport = Airport()
airport.loadFromFile(location)
airport.startSimulation()


CFRunLoopRun()

