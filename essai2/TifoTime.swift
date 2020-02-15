//
//  TifoTime.swift
//  essai2
//
//  Created by Frederic GIRY on 10/02/2020.
//  Copyright © 2020 FabasGalaxy. All rights reserved.
//

import UIKit
import TrueTime


class TifoTime: NSObject {
    
    var MonotonicalTimems: Int
    var ReferenceTimems: Double
    var TimeSince1970ms: Double
    var ntpService: TrueTimeClient
    
    
    override init() {
        
        MonotonicalTimems = -1
        ReferenceTimems = 0.0
        TimeSince1970ms = 0.0
        
        // demarrer le service NTP TrueTime
        ntpService = TrueTimeClient.sharedInstance
        ntpService.start()
        print("init myTifoTime")
        
    }
    
    func getMonotonicalTimems() -> Int {
        return MonotonicalTimems
    }
    
    func getReferenceTimems() -> Double {
        return ReferenceTimems
    }
    
    func getTimeSince1970ms() -> Double {
        return TimeSince1970ms
    }
    
    func getNTPtime () {
        
        let t1:Int = getMonotonicLocalTimems()
        
        // To block waiting for fetch, use the following:
        ntpService.fetchIfNeeded { result in
            switch result {
                case let .success(referenceTime):
                    let devicedDate = Date()
                    
                    let t4:Int = self.getMonotonicLocalTimems()
                    
                    let now = referenceTime.now()
                   
                    print ("A/R reseau (ms) : \(t4-t1)")
                    
                    print("referenceTime.time : \( referenceTime.time)")
                    print("referenceTime.uptime : \( referenceTime.uptime)")
                    print("referenceTime.uptimeInterval : \( referenceTime.uptimeInterval)")
                    
                   
                    self.MonotonicalTimems = (t1+t4)/2
                    print("Monotical (T1+T4)/2 : \(self.MonotonicalTimems)")
                    
                    // recuperer une estimation du temps de reference NTP
                    // au fur et a mesure cette reference devrait s ameliorer
                    self.ReferenceTimems = now.timeIntervalSinceNow
                    print("Delay (sec)  : \( self.ReferenceTimems)")
                    
                    // recuperer le temps ecoule depuis 1970
                    self.TimeSince1970ms = now.timeIntervalSince1970
                    print ("now.timeIntervalSince1970 : \(now.timeIntervalSince1970)")
                
                    print ("deviceDate : \(devicedDate.timeIntervalSince1970)")
                                            
                case let .failure(error):
                    print("Error getNTPtime ! \(error)")
            }
        }
    }
    
    public func getMonotonicLocalTimems() -> Int {
        var uptime = timespec()
        
        if 0 != clock_gettime(CLOCK_MONOTONIC, &uptime) {
            fatalError("Could not execute clock_gettime CLOCK_MONOTONIC errno: \(errno)")
        }
        return (uptime.tv_sec*1000 + uptime.tv_nsec/1000)
    }
}


