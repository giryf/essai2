//
//  ViewController.swift
//  essai2
//
//  Created by Frederic GIRY on 04/02/2020.
//  Copyright © 2020 FabasGalaxy. All rights reserved.
//

import UIKit
import TrueTime

class ViewController: UIViewController {
    
    let ipAddr = "90.89.226.19"
    let portVal = 21701

    var mLocalTimems = 0
    var mReferenceTimems = 0
    
    var serverSoc: DataSocket!
    
    var clientTrueTime: TrueTimeClient!
    
    var ntpTime: NTPTime!
    
    var timeReqSoc: TimeReq!
    var dataReqSoc: DataReq!
    
    // cette declaration lance le service TrueTime NTP
    // attention pour l instant le pool NTP = time.apple.com seulement, beurk
    var myTifoTime = TifoTime()
    
    // liste des animations SeqPix
    var mSeqPixList:[SeqPix] = []
    
    // pour chaque anim #1 #2 etc, recuperer la position dans mSeqPixList (commencant a 0)
    var mIndiceSeqPix:[Int] = [-1, -1, -1, -1]
    
    @IBOutlet weak var TicTac: UILabel!
    @IBOutlet weak var stadeId: UITextField!
    @IBOutlet weak var blocId: UITextField!
    @IBOutlet weak var rowId: UITextField!
    @IBOutlet weak var serverTimems: UILabel!
    @IBOutlet weak var localTimems: UILabel!
    @IBOutlet weak var seatId: UITextField!
    
    @IBOutlet weak var BtnSeqPix1: UIButton!
    @IBOutlet weak var BtnSeqPix2: UIButton!
    @IBOutlet weak var BtnSeqPix3: UIButton!
    @IBOutlet weak var BtnSeqPix4: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print (">>> Main viewDidLoad")
        // Do any additional setup after loading the view.
        
        // definition de l adresse de connexion au serveur
        serverSoc = DataSocket(ip: ipAddr, port: portVal)

        // Initialiser la synchro temps
        print ("-- NTP synchronisation")
        ntpTime = NTPTime()
        ntpTime.synchronize()
    
        // ecrire un fichier json de test
        print("-- write dummy Json")
        writeSeqPixJsonFile()
            
        // lire le fichier interne SeqPix.json
        print("-- read & deserialize Json")
        mSeqPixList = getSeqPixFromJsonFile()
        
        print("-- update UI")
        // mettre a jour l interface
        updateUILaunchAnim()
            
        TicTac.text = ""
    
    }
        
    override func viewDidAppear(_ animated: Bool) {
        
        // initialiser un tictac
        let _ = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ticTacGo), userInfo: nil, repeats: true)
        
        super.viewDidAppear(animated)
        
    }
    
    @objc func ticTacGo() {
        let sec = ntpTime.getNTPseconds()
        TicTac.text = String(sec)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        print ("\n>>> prepareSegue")
        var indiceAnim:Int = 0
        var countDownColor: UIColor = UIColor.white
        
        if segue.identifier == "RunTifo1" {
            indiceAnim = 0
            countDownColor = UIColor.blue
        }
        else if segue.identifier == "RunTifo2" {
            indiceAnim = 1
            countDownColor = UIColor.yellow
        }
        else if segue.identifier == "RunTifo3" {
            indiceAnim = 2
            countDownColor = UIColor.green
        }
        else if segue.identifier == "RunTifo4" {
            indiceAnim = 3
            countDownColor = UIColor.red
        }
        
        if segue.identifier == "RunTifo1" || segue.identifier == "RunTifo2" || segue.identifier == "RunTifo3" || segue.identifier == "RunTifo4" {
            let myFullScreen = segue.destination as! FullScreen
            
            myFullScreen.numTIFO = indiceAnim + 1
            
            // passer la sequence a FullScreen
            myFullScreen.currentSeqPix = mSeqPixList[indiceAnim]
            
            // remettre a jour la synchro temps si on a pu se connecter
            // sinon, ca veut dire qu on est synchrnonisé sur l heure du telephone...
            if ntpTime.NTPsynchro {
                ntpTime.getSNTPtime()
            }
            
            // demander a quel elapseTime on doit lancer l animation, et le passer a FullScreen
            let TIFOStartElapseTime = ntpTime.getAnimationStartElapseTimems()
            print("TIFOStartElapseTime : \(TIFOStartElapseTime)")
            myFullScreen.startElapseTime = TIFOStartElapseTime
            
            // couleur du countDown
            myFullScreen.countDownColor = countDownColor
            
           
        }
    }

    @IBAction func getTrueTime(_ sender: Any) {
      
        ntpTime.getSNTPtime()
    
    }
    

    @IBAction func getTimeReq(_ sender: Any) {
        let cmd = "timeReq"
        
        // init du socket
        timeReqSoc = TimeReq(with: self)
        
        // connexion serveur
        timeReqSoc.connectWith(socket: self.serverSoc)
        
        // recuperer le temps T1 MONOTONIC et le stcoker dans theSocket
        timeReqSoc.timeReq = true
        let T1:Int = Util.getMonotonicLocalTimems()
       
        timeReqSoc.T1 = T1
        
        // envoyer la demande de timeReq
        timeReqSoc.send(message: cmd)
        print("MainUI apres theSocket.send")
    }
    
    
    @IBAction func ValiderPlace(_ sender: Any) {
        let stade = stadeId.text ?? "ND"
        let bloc = blocId.text ?? "ND"
        let row = rowId.text ?? "ND"
        let seat = seatId.text ?? "ND"
        
        
        
        let cmd = "dataReq \"\(stade)\" \"\(bloc)\" \"\(row)\" \"\(seat)\""
        print ("cmd: >\(cmd)<")
    /*
        // init du socket
        dataReqSoc = DataReq(with: self)
        dataReqSoc.dataReq = true
        // connexion serveur
        
        dataReqSoc.connectWith(socket: serverSoc)
    
        // envoyer la demande de dataReq
        dataReqSoc.send(message: cmd)
        print("MainUI apres dataReq.send")
 */
        // ecrire un fichier json de test
        writeSeqPixJsonFile()
        
        // lire le fichier interne SeqPix.json
        mSeqPixList = getSeqPixFromJsonFile()
    
        // mettre a jour l interface
        updateUILaunchAnim()
        
    }
    

    func updateUILaunchAnim() {
        
        // Initialiser l etat des boutons
        BtnSeqPix1.isEnabled = false
        BtnSeqPix2.isEnabled = false
        BtnSeqPix3.isEnabled = false
        BtnSeqPix4.isEnabled = false
        
        // reperer chaque SeqPix dans mSeqPixList
        var indice = 0
        for seqPix in mSeqPixList {
            if seqPix.mPixSeqNum == "1" {
                mIndiceSeqPix[0] = indice
                BtnSeqPix1.isEnabled = true
            }
            if seqPix.mPixSeqNum == "2" {
                mIndiceSeqPix[1] = indice
                BtnSeqPix2.isEnabled = true
            }
            if seqPix.mPixSeqNum == "3" {
                mIndiceSeqPix[2] = indice
                BtnSeqPix3.isEnabled = true
            }
            if seqPix.mPixSeqNum == "4" {
                mIndiceSeqPix[3] = indice
                BtnSeqPix4.isEnabled = true
            }
            indice += 1
        }
        
        
    }
}


func getDocumentsDirectory() -> URL {
    
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    //print("URL documents : \(paths.first!)")
    return paths.first!
    
}



extension ViewController: TimeReqProtocol {
    func resetUI(status: Bool) {
        if (status) {
            serverTimems.text="0"
            localTimems.text="0"
        } else
        {
            serverTimems.text="-1"
            localTimems.text="0"
        }
    }
    
    func updateUI(serverMS: Int, localMS: Int) {
        serverTimems.text="\(serverMS)"
        localTimems.text="\(localMS)"
    }

    
}
