//
//  Util.swift
//  essai2
//
//  Created by Frederic GIRY on 13/02/2020.
//  Copyright © 2020 FabasGalaxy. All rights reserved.
//

import UIKit

class Util: NSObject {
    
    static public func getMonotonicLocalTimems() -> Int {
        var uptime = timespec()
        
        if 0 != clock_gettime(CLOCK_MONOTONIC, &uptime) {
            print("OUPS : erreur getMonotonicLocalTimesms")
            fatalError("Could not execute clock_gettime CLOCK_MONOTONIC errno: \(errno)")
            }
        return (uptime.tv_sec*1000 + uptime.tv_nsec/(1000*1000))
}
    
    static public func printDate( libelle:String , myDate:Date) {
        let formatDate = DateFormatter()
        formatDate.dateFormat = "HH:mm:ss.SSS"
        print(libelle + " : \t" + formatDate.string(from: myDate))
    }
    
}
