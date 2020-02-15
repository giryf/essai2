//
//  DataReq.swift
//  essai2
//
//  Created by Frederic GIRY on 04/02/2020.
//  Copyright © 2020 FabasGalaxy. All rights reserved.
//

import UIKit

class DataReq: NSObject, StreamDelegate {
    var readStream: Unmanaged<CFReadStream>?
    var writeStream: Unmanaged<CFWriteStream>?
    var inputStream: InputStream?
    var outputStream: OutputStream?
    var sizeToRead: Int
    var dataReq: Bool
    var nbJson:Int
    
    var answer: String
    var messages = [AnyHashable]()
    weak var uiPresenter: TimeReqProtocol!
    
    
    init(with presenter:TimeReqProtocol) {
        self.uiPresenter = presenter
        self.uiPresenter.resetUI(status: false)
        self.sizeToRead = -1
        self.answer = ""
        
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
                var msg:String
                
                // en premier, on doit recuperer le nbre de fichiers json qui vont etre envoyes
                if self.nbJson == 0 {
                    msg = readMsg()
                    print("msg:>\(msg)<")
                    if (msg != "ko"){
                        print("\(msg.count)")
                        self.nbJson = Int(msg)!
                    }
                    
                    self.answer = "["
                }
                
                // lecture des json
                if self.nbJson > 0 {
                    // lecture du nom du fichier, mais on n en a pas besoin
                    msg = readMsg()
                    // si on peut,on continue de lire pour recevoir le json
                    if msg != "ko" {
                        msg = readMsg()
                    }
                    if msg == "ko" {
                        print ("erreur de recuperation des json")
                        self.sizeToRead = -999
                    }
                    // ajouter le json aux precedents
                    self.answer += msg
                    self.nbJson -= 1
                    
                    print ("nbJson : \(self.nbJson)")
                    
                    if (self.nbJson == 0) {
                        self.sizeToRead = -999
                        
                        // fermer le JSON
                        self.answer += "]"
                        
                        print("answer:\(self.answer)")
                    }
                }
                
                // si on a fini ou erreur
                if self.sizeToRead == -999 {
                    send(message: "bye")
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
    
    public func readMsg () -> String {
        
        var dataBuffer = Array<UInt8>(repeating: 0, count: 100000)
        var cBuffer = Array<UInt8>(repeating: 0, count: 1)
        var output:String
        var txtSize:String = "0"
        
        var len: Int
        var resp:String = "ko"
        var stop:Bool = true
        var i:Int
        var size:Int
        
        var test:String
        
        i = 0
        //lire le premier caractere du flux
        // puis lire jusqu a trouver un caractere blanc
        // decoder alors cette chaine en Int pour savoir combien il y a de caracateres a lire ensuite
        len = (inputStream?.read(&cBuffer, maxLength: 1))!
        output = String(bytes: cBuffer, encoding: .ascii)!
        print ("readMsg : i=\(i) >\(output)<")
        stop = true
        if len > 0 {
            stop = false
        }
        
        var myText = Array(output)
        txtSize.append(myText[0])
        
        while !stop {
            dataBuffer[i] = cBuffer[0]
            i = i + 1
            len = (inputStream?.read(&cBuffer, maxLength: 1))!
            output = String(bytes: cBuffer, encoding: .ascii)!
            
            print ("readMsg : i=\(i) >\(output)<")
            if output == " " {
                print ("stop")
                stop = true
            } else
            {
                myText = Array(output)
                txtSize.append(myText[0])
            }
            
            
        }
        
        // combien de caracteres a lire :
        size = Int(txtSize)!
        print ("readMsg : size=\(size)")
        
        if size > dataBuffer.count {
            resp = "ko"
            print ("Buffer trop petit")
            return resp
        }
        
        var nbLus:Int = 0
        //var offset:Int
        while (nbLus < size) {
            //offset = nbLus
            len = (inputStream?.read(&dataBuffer[nbLus], maxLength: (size - nbLus)))!
            nbLus += len
        }
        
    
        // supprimer les [ et ] en debut et fin de chaine
        test = String(bytes: dataBuffer, encoding: .ascii)!
        if test.hasPrefix("[") {
            
            let myText = Array(String(test.prefix(size)))
            
            // il y a des caracteres invisibles derriere le ], donc
            stop = false
            i=1
            while !stop
            {
                print("i:\(i) >\(myText[size-i])<")
                if myText[size-i] == "]" {
                    stop = true
                    print("youpi ] de merde")
                } else{
                    i=i+1
                }
            }
            resp = String(test.prefix(size-i))
            resp = String(resp.dropFirst(1))
            
        } else
        {
            resp = String(test.prefix(size))
        }
        
        print ("Resp:>\(resp)<")
        if nbLus != size {
            resp = "ko"
        }
        return resp
    }
}

