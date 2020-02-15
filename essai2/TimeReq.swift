//
//  TimeReq.swift
//  essai2
//
//  Created by Frederic GIRY on 04/02/2020.
//  Copyright © 2020 FabasGalaxy. All rights reserved.
//

import UIKit

class TimeReq: NSObject , StreamDelegate {
    
    var readStream: Unmanaged<CFReadStream>?
    var writeStream: Unmanaged<CFWriteStream>?
    var inputStream: InputStream?
    var outputStream: OutputStream?
    var sizeToRead: Int
    var timeReq: Bool
    var dataReq: Bool
    var nbJson:Int
    var T1: Int
    var T4: Int
    var elapseTimeRef:Int
    var realTimeRef:Int
    var answer: String
    var messages = [AnyHashable]()
    weak var uiPresenter: TimeReqProtocol!
    
    
    init(with presenter:TimeReqProtocol) {
        self.uiPresenter = presenter
        self.uiPresenter.resetUI(status: false)
        self.sizeToRead = -1
        self.answer = ""
        self.T1=0
        self.T4=0
        self.realTimeRef=0
        self.elapseTimeRef=0
        self.timeReq=false
        self.dataReq=false
        self.nbJson=0
    }
    
    
    func connectWith(socket: DataSocket) {
        print (">>---- connectWith:\(String(describing: socket.ipAdd)) port:\(String(describing: socket.port))")
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (socket.ipAdd! as CFString), UInt32(socket.port), &readStream, &writeStream)
        messages = [AnyHashable]()
        
        open()
        
        print ("<< connectWith")
    }
    
    func disconnect(){
        close()
    }
    
    
    func open() {
        print (">>---- Opening streams")
        outputStream=writeStream?.takeRetainedValue()
        inputStream=readStream?.takeRetainedValue()
        outputStream?.delegate = self
        inputStream?.delegate = self
        outputStream?.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
        inputStream?.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
        
        outputStream?.open()
        inputStream?.open()
        print ("<< Opening streams")
        
    }
    
    func close() {
        print (">>---- Closing Streams")
        //uiPresenter?.resetUI(status: false)
        inputStream?.close()
        outputStream?.close()
        outputStream?.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
        inputStream?.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
        inputStream?.delegate = nil
        outputStream?.delegate = nil
        inputStream = nil
        outputStream = nil
        print ("<< Closing Streams")
        
        
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        print (">>---- func stream : eventCode \(eventCode)")
        switch eventCode {
        case .openCompleted:
            uiPresenter?.resetUI(status: true)
            print ("case .openedCompleted")
        case .hasBytesAvailable:
            print ("case .hasBytesAvailable")
            if aStream == inputStream {
                var dataBuffer = Array<UInt8>(repeating: 0, count: 1024)
                var len: Int
                while (inputStream?.hasBytesAvailable)! {
                    len = (inputStream?.read(&dataBuffer, maxLength: 1024))!
                    print("len : \(len)")
                    if len > 0 {
                        var output = String(bytes: dataBuffer, encoding: .ascii)
                        
                        if nil != output {
                            
                            // si on n a pas encore la taille ou le nbre de fichiers de ce qu il y aura a lire ensuite, la stocker
                            if (self.sizeToRead == -1 && self.nbJson == 0) {
                                
                                print ("==== ca doit etre le debut ca ===")
                                print(">\(output!)<")
                                // si on est dans une demande de timeReq, evaluer le temps T4, tout de suite
                                if (self.timeReq) {
                                    print("et MERDE : T4 dans timereq pas bon")
                                    self.T4 = Util.getMonotonicLocalTimems()
                                    //self.T4 = 0
                                    
                                }
                                
                                // mettre le texte lu dans un tableau pour en rechercher le premier blanc et extraire la taille de
                                // ce qu il y aura a lire ensuite
                                // car il arrive que tout arrive d un coup et non pas d abord la taille, puis la data
                                let myText = Array(output!)
                                var txtnbcar:String = "0"
                                var i:Int = 0
                                while myText[i] != " " && i<len {
                                    txtnbcar.append(myText[i])
                                    i += 1
                                }
                                // i pointe sur le blanc
                                i += 1
                               
                                // il y a un blanc apres le nbre de caracteres ou le nbre de fichiers pour la prochaine fois
                                //let nbcar = output!.prefix(len-1)
                                if self.timeReq {
                                    self.sizeToRead = Int(txtnbcar)!
                                    print("txtnbcar:\(Int(txtnbcar)!)")
                                }
                                
                                // si la chaine output est plus longue que la seule taille de ce qu il y a a lire
                                // c est qu on a recu + que seulement la taille, et on doit supprimer le début
                                if i+1 != len {
                                    output = String(describing: output?.dropFirst(i+1))
                                    len = len - (i+1)
                                    print ("ce qu il reste len=\(len) drop : >\(output!)<")
                                    
                                } else {
                                    len = 0
                                }
                                
                            }
                            // cas timeReq
                            if self.timeReq {
                                // si on a deja lu la taille et qu il y a qq chose a lire
                                // on reteste len car il a peut etre ete modifie
                                if self.sizeToRead != -1 && len > 0
                                {
                                    // decrementer la size de ce qu il y avait a lire
                                    if len <= self.sizeToRead {
                                        self.sizeToRead -= len
                                    } else
                                    {
                                        // dans ce cas, on a un pb de protocole
                                        self.sizeToRead = 0
                                    }
                                    
                                    // stocker en mode append la reponse
                                    self.answer.append(output!)
                                    
                                }
                            }
                            
                            print("Recu : >\(self.answer)<")
                            
                    
                        }
                    }
                }
                
                // si on est dans un timeReq
                // si le nombre de byte a lire est =0 ici, c est qu on a fini de lire ce qu on attendait
                // on peut donc clore le socket
                if timeReq {
                    if self.sizeToRead == 0 {
                        self.sizeToRead = -999
                        send(message: "bye")
                        
                        // si on etait dans une demande de timeReq
                        if (self.timeReq) {
                            var T2min:Int = 0,T2sec:Int = 0, T2ms:Int = 0
                            var T3min:Int = 0,T3sec:Int = 0, T3ms:Int = 0
                            var T2:Int , T3:Int
                            print("answer:\(answer)")
                            let scanner = Scanner(string: self.answer)
                            scanner.scanInt(&T2min)
                            print(T2min)
                            
                            let _=scanner.scanString(" ")
                            scanner.scanInt(&T2sec)
                            print(T2sec)
                            let _=scanner.scanString(" ")
                            scanner.scanInt(&T2ms)
                            let _=scanner.scanString(" ")
                            scanner.scanInt(&T3min)
                            let _=scanner.scanString(" ")
                            scanner.scanInt(&T3sec)
                            let _=scanner.scanString(" ")
                            scanner.scanInt(&T3ms)

                            T2 = (T2min * 60 + T2sec)*1000 + T2ms
                            T3 = (T3min * 60 + T3sec)*1000 + T3ms
                            
                            print ("T2=\(T2) T3=\(T3)")
                            print ("T1=\(self.T1) T4=\(self.T4)")
                            
                            self.realTimeRef = (T2+T3)/2
                            self.elapseTimeRef = (self.T1+self.T4)/2
                            
                            uiPresenter?.updateUI(serverMS: self.realTimeRef, localMS: self.elapseTimeRef)
                        }
                    }
                }
                
            }
        case .hasSpaceAvailable:
            print("case .hasSpaceAvailable")
            
            // si sizeToRead = -999, c est qu on veur fermer le socket
            if self.sizeToRead == -999 {
                disconnect()
            }
        case .errorOccurred:
            print ("errorOccured : \(aStream.streamError?.localizedDescription ?? "")")
        case .endEncountered:
            aStream.close()
            aStream.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
            print ("close stream")
            uiPresenter?.resetUI(status: false)
        default:
                print("unkown event")
            
        }
        print ("<< func stream")
        
    }

    func send(message: String) {
        print (">>---- send")
        let size = message.count
        let request="\(size)"+" \(message)"
        print ("request:\(request)")
        
        let buff = [UInt8](request.utf8)
        if let _ = request.data(using: .ascii) {
            let res = outputStream?.write(buff, maxLength: buff.count)
            print ("res:\(res ?? 9999)")
        }
        print ("<< send")
        
    }
    
 
}

public struct DataSocket {
    let ipAdd: String!
    let port: Int!
    
    init(ip:String, port:Int) {
        self.ipAdd = ip
        self.port = Int(port)
    }
}

