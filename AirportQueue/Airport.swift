//
//  Airport.swift
//  AirportQueue
//
//  Created by Benjamin Johnson on 10/09/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation


protocol AirportProtocol {
    func didFinishProcessingPassenger(passenger: Passenger)
}

class Airport: AirportProtocol {

    var queueStats: QueueStats!
    var servers: [Server] = []
    var totalPassengerCount: Int = 0
    var passengers: [Passenger] = []
    var passengerCount = 0
    
    let businessQueue = PriorityQueue<Passenger>({ $0.arrivalTime < $1.arrivalTime })
    let economyQueue = PriorityQueue<Passenger>({ $0.arrivalTime < $1.arrivalTime })
    
    func loadFromFile(filename: String ) {
        if let aStreamReader = StreamReader(path: location) {
            // Close file when complete the following code
            defer {
                aStreamReader.close()
            }
            
            // Get number of servers
            let attributes = aStreamReader.nextLine()!.componentsSeparatedByString(",")
            
            let numberOfEconomyServers = Int(attributes[0])!
            let numberOfBusinessServers = Int(attributes[1].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()))!
            
            // Setup Servers
            for var e = 0; e < numberOfEconomyServers;e++ {
                let economyServer = Server(queue: economyQueue, delegate: self)
                servers.append(economyServer)
            }
            
            for var b = 0; b < numberOfBusinessServers;b++ {
                let businessServer = Server(queue: businessQueue, delegate: self)
                servers.append(businessServer)
            }
            
            // Add passengers to queues
            while let line = aStreamReader.nextLine() {
                
                let components = line.componentsSeparatedByString(",")
                
                let arrivalTime = (components[0] as NSString).doubleValue
                let serviceTime = (components[1] as NSString).doubleValue
                let airlineClass = AirlineClass(rawValue: (components[2] as NSString).integerValue)!
                if serviceTime > 0 {
                    let newPassenger = Passenger(airlineClass: airlineClass, arrivalTime: arrivalTime, serviceTime: serviceTime)
                    passengers.append(newPassenger)
                }

            }
            
        } else {
            fatalError("Cannot load file")
        }

    }
    
    func prepareForPassenger(passenger: Passenger) {
        // Append to array
        passengers.append(passenger)
        // Setup delay based
        passengerCount++
        
        delay(passenger.arrivalTime) {
            // Dispatch to main queue
            dispatch_async(dispatch_get_main_queue(),{
                passenger.startedWaiting = NSDate()
                switch(passenger.airlineClass) {
                case .Economy:
                    self.economyQueue.push(passenger)
                    self.queueStats.updateQueue(passenger.airlineClass, queueLength: self.economyQueue.count)
                case .Business:
                    self.businessQueue.push(passenger)
                    self.queueStats.updateQueue(passenger.airlineClass, queueLength: self.businessQueue.count)

                }
                // Try and find server who is ready
                for server in self.servers where server.isReady {
                    server.callNextPassenger()
                    break
                }
                
            })
        }
        
    }
    
    func startSimulation() {
        // Setup QStats
        queueStats = QueueStats(servers: servers)
        
        // Schedule sampling
        NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "recordQueueSample", userInfo: nil, repeats: true)

        
        for passenger in passengers {
            prepareForPassenger(passenger)
        }
    }
    
    func didFinishProcessingPassenger(passenger: Passenger) {
        print("\(passengerCount) Finished serving \(passenger.airlineClass) passenger")
        // Update Stats
        
        switch(passenger.airlineClass) {
        case .Economy:
            queueStats.numberOfPeopleServedInEconomy++
            queueStats.totalWaitTimeForEconomy += passenger.totalWaitTime

        case .Business:
            queueStats.numberOfPeopleServedInBussines++
            queueStats.totalWaitTimeForBusiness += passenger.totalWaitTime
        }
        queueStats.totalServiceTime += passenger.serviceTime
        queueStats.lastCompleteServiceTime = NSDate()
        passengerCount--
        if passengerCount == 0 {
            print("Finished processing all passengers")
            queueStats.printStat()
            exit(0)
        }
        
    }
    
   @objc func recordQueueSample() {
        queueStats.economyQueueLengthSamples.append(economyQueue.count)
        queueStats.businessQueueLengthSamples.append(businessQueue.count)
    }
    
}