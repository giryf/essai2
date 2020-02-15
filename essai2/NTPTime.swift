//
//  NTPTime.swift
//  essai2
//
//  Created by Frederic GIRY on 13/02/2020.
//  Copyright © 2020 FabasGalaxy. All rights reserved.
//

import UIKit
import NHNetworkTime

class NTPTime: NSObject {

    var ElapseTimeRefms: Int // temps ecoule en msec depuis le dernier reboot
    var NTPRefmmssms: Int // reference de temps NTP mm:ss.sss equivalente a ElapseTimeRefms
    var NTPTimeSince1970ms: Int // temps NTP en msec ecoule depuis 01/01/1970
    var OffsetLocalNTPms:Int // offset entre l heure locale et la ref NTP (pas utilise en fait)
    var NTPsynchro:Bool // booleen indiquant si la synchro NTP est faite
    let sharedNetworkClock = NHNetworkClock() // le process de synchro NTP
    
    override init() {
        
        // initialiser le temps ecoule depuis le dernier reboot en msec
        ElapseTimeRefms = Util.getMonotonicLocalTimems()
        
        // initialiser la reference de temps avec l heure du device
        // cette reference sera ensuite mise à jour via l heure NTP (si possible)
        let deviceDate = Date()
        let calendar = Calendar.current
        let min = calendar.component(.minute, from: deviceDate)
        let sec = calendar.component(.second, from: deviceDate)
        let nano = calendar.component(.nanosecond, from: deviceDate)
        let ms: Int = nano/(1000*1000)
        
        
        NTPRefmmssms = min * 60 * 1000 + sec * 1000 + ms
        
        // indiquer que la synchro n est pas faite
        NTPsynchro = false
        
        NTPTimeSince1970ms = 0
        OffsetLocalNTPms = 0
        
    }
    
    
    func synchronize() {
        // demarrer la synchro NTP
        print("SharedNetworkClock synchronize")
        sharedNetworkClock.synchronize()
        
        // on sera prevenu de la synchro via une notification interne
        NotificationCenter.default.addObserver(self, selector: #selector(networkTimeSyncCompleteNotification), name: NSNotification.Name(rawValue: kNHNetworkTimeSyncCompleteNotification), object: nil)
    }
    
    
    @objc func networkTimeSyncCompleteNotification() {
        // y a un petit bug dans la librairie NHNetworkTime, isYnchronized aurait du etre mis à true avant d emettre
        // la notification, mais normalement, on est bien synchronisé qd on la recoit
        print (">> Synchronized Notification")
        
        // acquerir et stcoker les references de temps
        getSNTPtime()
    }
    
    func getNTPseconds() -> Int {
        // combien de ms se sont ecoulees depuis la prise de reference elapse/NTP
        let currentElapsems:Int = Util.getMonotonicLocalTimems()
        let deltaMonotonicms =  currentElapsems - self.ElapseTimeRefms
        //print("deltaMonotonicms : \(deltaMonotonicms)")
        
        // calculer l equivalent en temps NTP
        let nowNTPminsecms = self.NTPRefmmssms + deltaMonotonicms
        //print("nowNTPminsecms: \(nowNTPminsecms)")
        var seconds:Int = nowNTPminsecms / 1000
        seconds = seconds % 60
        return seconds
    }
    
    func getSNTPtime() {
        
        let oldElapse = ElapseTimeRefms
        let oldNTP = NTPRefmmssms
        
        let t1 = Util.getMonotonicLocalTimems()
        let NTPtime = sharedNetworkClock.networkTime!
        let t4 = Util.getMonotonicLocalTimems()
        let deviceDate = Date()
        
        print("\n")
        // stocker le temps ecoule depuis le dernier reboot en supposant que NTPtime aura ete acquis au milieu
        ElapseTimeRefms = (t1 + t4)/2
        print("t4-t1 = \(t4 - t1)")
        
        // recuperer de l heure NTP, min, sec et msec pour les aligner avec ElapseTimeRefms, on se moque des heures
        let calendar = Calendar.current
        let min = calendar.component(.minute, from: NTPtime)
        let sec = calendar.component(.second, from: NTPtime)
        let nano = calendar.component(.nanosecond, from: NTPtime)
        let ms: Int = nano/(1000*1000)
        
        NTPRefmmssms = min * 60 * 1000 + sec * 1000 + ms
        
        // indiquer que la synchro est faite
        NTPsynchro = true
        
        // temps NTP ecoule depuis 01/01/1970
        NTPTimeSince1970ms = Int(NTPtime.timeIntervalSince1970 * 1000)
        
        // stocker l offset
        OffsetLocalNTPms = Int(sharedNetworkClock.networkOffset * 1000)
        
        let formatDate = DateFormatter()
        formatDate.dateFormat = "HH:mm:ss.SSS"
        print("SNTP Time : " + formatDate.string(from: NTPtime))
        print("Device Time : " + formatDate.string(from: deviceDate))
        print("ElapseTimeRefms : \(ElapseTimeRefms)")
        print("NTPRefmmssms : \(NTPRefmmssms)")
        print("NTPsynchro : \(NTPsynchro)")
        print("NTPTimeSince1970ms : \(NTPTimeSince1970ms)")
        print("OffsetLocalNTPms : \(OffsetLocalNTPms)")
        
        print ("Variation elapse : \(ElapseTimeRefms - oldElapse)")
        print ("Variation NTP : \(NTPRefmmssms - oldNTP)")
        
    }
    
    func getAnimationStartElapseTimems () -> Int {
        // cette fonction retourne le temps en elapse time (temps ecoule depuis le dernier reboot) de lancement de l animation
        // on veut lancer l animation a la prochaine minute:00.000
        
        
        
        // combien de ms se sont ecoulees depuis la prise de reference elapse/NTP
        let currentElapsems:Int = Util.getMonotonicLocalTimems()
        let deltaMonotonicms =  currentElapsems - self.ElapseTimeRefms
        print("currentElapsems : \(currentElapsems)")
        print("deltaMonotonicms : \(deltaMonotonicms)")
        
        // calculer l equivalent en temps NTP
        let nowNTPminsecms = self.NTPRefmmssms + deltaMonotonicms
        print("nowNTPminsecms : \(nowNTPminsecms)")
        
        var seconds:Int = nowNTPminsecms / 1000
        let restems:Int = nowNTPminsecms - seconds * 1000
        
        seconds = seconds % 60
        
        let deltams:Int
        if seconds > 30 {
            // la prochaine minute:00.000 du serveur est dans :
            deltams = 60 * 1000 - (seconds * 1000 + restems)
            
        } else
        {
            // trop tard
            deltams = 0
        }
        
        print("deltams : \(deltams)")
        
        
        // on veut donc lancer l animation en elapse time a :
        
        return self.ElapseTimeRefms + deltaMonotonicms + deltams
        
    }
    

    
}

