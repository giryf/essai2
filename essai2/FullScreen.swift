//
//  FullScreen.swift
//  essai2
//
//  Created by Frederic GIRY on 08/02/2020.
//  Copyright © 2020 FabasGalaxy. All rights reserved.
//

import UIKit

class FullScreen: UIViewController {
    
    var counter = 0
    var countDownTimer = Timer()
    var isCountDownRunning = false
    var countDownColor = UIColor.white
    var indice = 0
    var numTIFO = 0
    var startElapseTime = 0
    
    var currentSeqPix: SeqPix?
    
    let currentBrightness = UIScreen.main.brightness


    @IBOutlet var tifoColor: UIView!
    @IBOutlet weak var countDown: UILabel!
    @IBOutlet weak var invit: UILabel!
    
    override func viewDidLoad() {
    super.viewDidLoad()
       
        print (">> viewDidiLoad Fullscreen")
        print("numTIFO : \(numTIFO)")
        print("startElapseTime : \(startElapseTime)")
        
        invit.text = ""
        countDown.text = ""
        
        UIScreen.main.brightness = CGFloat(1.0)
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        
        print ("\n<<< Fullscreen viewWillDisappear")
        UIApplication.shared.isIdleTimerDisabled = false
        
        UIScreen.main.brightness = currentBrightness
        super.viewWillDisappear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print ("\n>>> FullScreen viewDidAppear")
       
        // calculer dans combien de ms il faut lancer l anim : StartInms
        let currentElapsems = Util.getMonotonicLocalTimems()
        let currentDeviceDate = Date()
        Util.printDate(libelle: "currentDeviceDate", myDate: currentDeviceDate)
        let StartInms:Double = Double(startElapseTime - currentElapsems)/1000
        var fireDate: Date
        
        // Si on  n est pas en retard : 
        if StartInms > 0 {
            
            indice = 0
            
            // initialiser un compte à rebours jusqu au lancement de l animation
            if isCountDownRunning == false {
                runCountDownTimer()
                countDown.textColor = countDownColor
                invit.textColor = countDownColor
                
            }
            
            // calculer l heure de demarrage du TIFO en heure local
            fireDate = currentDeviceDate.addingTimeInterval(TimeInterval(StartInms))
            Util.printDate(libelle: "fireDate", myDate: fireDate)
               
            // armer le premier changement de couleur (indice = 0)
            var timer = Timer(fireAt: fireDate, interval: 0, target: self, selector: #selector(changeColor), userInfo: nil, repeats: false)
            RunLoop.main.add(timer, forMode: .common)
            
            // indice est incremente par changeColor
            let nbDurees:Int = (currentSeqPix?.mDurees!.count)!
            
            for i in 1..<nbDurees {
        
                // ajouter au fireDate precedent la duree de la sequence courante
                let duree:Int = Int((currentSeqPix?.mDurees![i-1])!)!
                fireDate = fireDate.addingTimeInterval(TimeInterval(Double(duree)/1000))
                // armer le changement de couleurs
                timer = Timer(fireAt: fireDate, interval: 0, target: self, selector: #selector(changeColor), userInfo: nil, repeats: false)
                RunLoop.main.add(timer, forMode: .common)
                
            }
            
            // armer le dernier changement
            let duree:Int = Int((currentSeqPix?.mDurees![nbDurees-1])!)!
            fireDate = fireDate.addingTimeInterval(TimeInterval(Double(duree)/1000))
            timer = Timer(fireAt: fireDate, interval: 0, target: self, selector: #selector(changeColor), userInfo: nil, repeats: false)
            RunLoop.main.add(timer, forMode: .common)
            
        } else {
            countDown.text = "Trop tard !"
        }
    }


    @objc func changeColor() {
        var color:UIColor
        //countDown.text = String(indice)
        if indice < (currentSeqPix?.mCouleurs!.count)! {
            color = colorWithHexString(hexString: (currentSeqPix?.mCouleurs![indice])!)
            tifoColor.backgroundColor = color
            indice += 1
        }
        // cas de la derniere duree
        else
        {
            let endElapse = Util.getMonotonicLocalTimems()
            color = colorWithHexString(hexString: "#000000")
            tifoColor.backgroundColor = color
            countDown.text = "The end ! \(endElapse - startElapseTime ) ms"
            countDown.font = countDown.font.withSize(25)
            countDown.sizeToFit()
        }
        
    }
    
    func runCountDownTimer() {
        countDownTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(TikTokStart), userInfo: nil, repeats: true)
        isCountDownRunning = true
    }
    
    @objc func TikTokStart() {
        
        // recuperer le temps elapse courant et le comparer au temps elapse de demarrage de la sequence
        let currentElapsems = Util.getMonotonicLocalTimems()
        let restems = startElapseTime - currentElapsems
        // si on approche de la fin du compte a rebours, on invalide le countDownTimer
        if  restems < 100 {
            countDownTimer.invalidate()
            isCountDownRunning = false
            countDown.text = ""
            countDown.font = countDown.font.withSize(24)
            invit.text = ""
            
        } else {
            let seconds:Int = (restems/1000)
            let millis = restems - seconds * 1000
            let cents = millis / 100
            let txt:String
            if seconds == 0 {
                txt = "GO"
            } else
            {
                txt = String(seconds)
            }
            
            //let sizeSP:Int = (100 - 72 * (seconds%2)) + (2 * (seconds%2) - 1) *  cents * 8
            let sizeSP:Int = (185 - 135 * (seconds%2)) + (2 * (seconds%2) - 1) *  cents * 15
            countDown.text = txt
            countDown.font = countDown.font.withSize(CGFloat(sizeSP))
            countDown.sizeToFit()
            
            if seconds%2 == 0 {
                invit.text = "Screen to the game !"
                
            } else {
                invit.text = ""
            }
            //countDown.sizeToFit()
        }
        
        
    }

    
    func colorWithHexString(hexString: String, alpha:CGFloat = 1.0) -> UIColor {

        // Convert hex string to an integer
        let hexint = Int(self.intFromHexString(hexStr: hexString))
        let red = CGFloat((hexint & 0xff0000) >> 16) / 255.0
        let green = CGFloat((hexint & 0xff00) >> 8) / 255.0
        let blue = CGFloat((hexint & 0xff) >> 0) / 255.0

        // Create color object, specifying alpha as well
        let color = UIColor(red: red, green: green, blue: blue, alpha: alpha)
        return color
    }
//    func intFromHexString(hexStr: String) -> UInt32 {
    func intFromHexString(hexStr: String) -> UInt64 {
        //var hexInt: UInt32 = 0
        var hexInt: UInt64 = 0
        // Create scanner
        let scanner: Scanner = Scanner(string: hexStr)
        // Tell scanner to skip the # character
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "#")
        // Scan hex value
        //scanner.scanHexInt32(&hexInt)
        scanner.scanHexInt64(&hexInt)
        return hexInt
    }
}
