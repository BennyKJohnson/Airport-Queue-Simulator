//
//  AirportTypes.swift
//  AirportQueue
//
//  Created by Benjamin Johnson on 11/09/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation

enum AirlineClass: Int, CustomStringConvertible {
    case Economy
    case Business
    var description: String {
        switch(self) {
        case .Economy:
            return "economy"
        case .Business:
            return "business"
        }
    }
}

class Passenger {
    let airlineClass: AirlineClass
    let arrivalTime: NSTimeInterval
    let serviceTime: NSTimeInterval
    var startedWaiting: NSDate!
    var totalWaitTime: NSTimeInterval = 0
    
    init(airlineClass: AirlineClass, arrivalTime: NSTimeInterval, serviceTime: NSTimeInterval) {
        self.airlineClass = airlineClass
        self.arrivalTime = arrivalTime
        self.serviceTime = serviceTime
    }
}



class Server {
    let queue: PriorityQueue<Passenger>
    var isReady: Bool = true
    var totalIdleTime: NSTimeInterval = 0
    var waitingSince: NSDate?
    var delegate: AirportProtocol
    init(queue: PriorityQueue<Passenger>, delegate: AirportProtocol) {
        self.queue = queue
        self.waitingSince = NSDate()
        self.delegate = delegate
    }
    
    func servePassenger(passenger: Passenger) {
        isReady = false
        // Update Passenger total wait time
        passenger.totalWaitTime = NSDate().timeIntervalSinceDate(passenger.startedWaiting)
        
        // Calculate Idle time
        if let waitingSince = waitingSince {
            totalIdleTime += NSDate().timeIntervalSinceDate(waitingSince)
        }
        waitingSince = nil
        
        delay(passenger.serviceTime) {
            // Dispatch to main queue
            dispatch_async(dispatch_get_main_queue(),{
                // Log Results
                self.delegate.didFinishProcessingPassenger(passenger)
                //queueStats.numberOfPeopleServed++
                self.callNextPassenger()
                
            })
        }
    }
    
    
    func callNextPassenger() {
        // If there is a passenger waiting in the queue. Serve them
        if let nextPassenger = queue.pop() {
            servePassenger(nextPassenger)
        } else {
            isReady = true
            if waitingSince == nil {
                waitingSince = NSDate()
                
            }
        }
    }
}


class QueueStats {
    // Served Count
    var numberOfPeopleServedInBussines: Int = 0
    var numberOfPeopleServedInEconomy: Int = 0
    
    var totalWaitTimeForBusiness: NSTimeInterval = 0
    var totalWaitTimeForEconomy: NSTimeInterval = 0
    
    var timeOfLastService: NSTimeInterval = 0
    let servers: [Server]
    var lastCompleteServiceTime: NSDate?
    var totalServiceTime: NSTimeInterval = 0
    
    var businessQueueLengthSamples: [Int] = []
    var economyQueueLengthSamples: [Int] = []
    
    var maxLengthOfQueue: [AirlineClass: Int] = [.Economy: 0, .Business: 0]
    
    var averageServiceTime: NSTimeInterval {
        return totalServiceTime / Double(numberOfPeopleServed)
    }
    
    var numberOfPeopleServed: Int {
        return numberOfPeopleServedInBussines + numberOfPeopleServedInEconomy
    }
    
    var averageWaitTimeForEconomy: NSTimeInterval {
        return totalWaitTimeForEconomy / Double(numberOfPeopleServedInEconomy)
    }
    
    var averageWaitTimeForBusiness: NSTimeInterval {
        return totalWaitTimeForBusiness / Double(numberOfPeopleServedInBussines)
    }
    
    var averageWaitTime: NSTimeInterval {
        return (totalWaitTimeForBusiness + totalWaitTimeForEconomy) / Double(numberOfPeopleServed)
    }
    
    var averageLengthForEconomy: Int {
        return economyQueueLengthSamples.reduce(0, combine: +) / economyQueueLengthSamples.count
    }
    
    var averageLengthForBusiness: Int {
        return businessQueueLengthSamples.reduce(0, combine: +) / businessQueueLengthSamples.count
        
    }
    
    init(servers: [Server]) {
        self.servers = servers
    }
    
    func updateQueue(airlineClass: AirlineClass, queueLength: Int) {
        maxLengthOfQueue[airlineClass] = max(maxLengthOfQueue[airlineClass]!, queueLength)
    }
    
    func printStat() {
        print("STATS")
        print("Number of people served: \(numberOfPeopleServed)")
        if let lastCompleteServiceTime = lastCompleteServiceTime {
            print("Last completed service \(lastCompleteServiceTime)")
        }
        
        print("Average Service Time: \(averageServiceTime)")
        
        print("Average wait time for Economy: \(averageWaitTimeForEconomy)")
        print("Average wait time for Business: \(averageWaitTimeForBusiness)")
        print("Average wait time: \(averageWaitTime)")
        
        print("Average Queue length of Economy: \(averageLengthForEconomy)")
        print("Average Queue length of Business \(averageLengthForBusiness)")
        
        print("Maximum Queue length for Economy: \(maxLengthOfQueue[.Economy]!)")
        print("Maximum Queue length for Business: \(maxLengthOfQueue[.Business]!)")
        
        for (index, server) in servers.enumerate() {
            print("Server \(index) indle time: \(server.totalIdleTime)")
        }
    }
    
}
