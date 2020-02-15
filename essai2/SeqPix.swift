//
//  SeqPix.swift
//  essai2
//
//  Created by Frederic GIRY on 14/02/2020.
//  Copyright © 2020 FabasGalaxy. All rights reserved.
//

import UIKit

class SeqPix: Decodable {
    var mPixSeqName: String
    var mPixSeqNum: String
    var mPixSeqType: String?
    var mExecDate: String?
    var mCouleurs:[String]?
    var mDurees:[String]?
    
    init() {
        mPixSeqName = ""
        mPixSeqNum = "-1"
    }
    
}


// Fonction provisoire
func writeSeqPixJsonFile() {
    
   
    let txt = """
            [
                {
                "mPixSeqName":"anim1",
                "mPixSeqNum":"1",
                "mPixSeqType":"screen",
                "mCouleurs":["#000000","#FFFFFF", "#000000", "#FFFFFF", "#000000", "#FFFFFF", "#000000", "#FFFFFF", "#000000", "#FFFFFF", "#000000", "#FFFFFF", "#000000", "#FFFFFF", "#000000", "#FFFFFF", "#000000", "#FFFFFF", "#000000", "#FFFFFF", "#000000", "#FFFFFF", "#000000", "#FFFFFF", "#000000", "#FFFFFF", "#000000", "#FFFFFF", "#000000", "#FFFFFF", "#000000", "#FFFFFF", "#000000", "#FFFFFF", "#000000", "#FFFFFF", "#000000", "#FFFFFFF", "#000000", "#FFFFFF"],
            "mDurees":["500","500","1500","500","1500","500","500","500","500","500","500","500","500","500","500","500","500","500","500","500","500","500","500","1000","500","500","500","4000","500","1500","500","1500","500","1500","500","1000","500","500","500","1000"]
                },
                {
                "mPixSeqName":"anim2",
                "mPixSeqNum":"2",
                "mPixSeqType":"screen",
                "mCouleurs":["#0000FF","#FFFFFF", "#FF0000", "#0000FF","#FFFFFF", "#FF0000", "#0000FF","#FFFFFF", "#FF0000", "#0000FF","#FFFFFF", "#FF0000", "#0000FF","#FFFFFF", "#FF0000", "#0000FF","#FFFFFF", "#FF0000", "#0000FF","#FFFFFF", "#FF0000", "#0000FF","#FFFFFF", "#FF0000", "#0000FF","#FFFFFF", "#FF0000", "#0000FF","#FFFFFF", "#FF0000", "#0000FF","#FFFFFF", "#FF0000", "#0000FF","#FFFFFF", "#FF0000", "#0000FF","#FFFFFF", "#FF0000"],
            "mDurees":["500","500","1500","500","1500","500","500","500","500","500","500","500","500","500","500","500","500","500","500","500","500","500","500","1000","500","500","500","4000","500","1500","500","1500","500","1500","500","1000","500","500","1500"]
                        }
            ]
            """
    
        let filename = getDocumentsDirectory().appendingPathComponent("SeqPix.json")
        do {
            try txt.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print ("echec d ecriture")
        }
    
}

func getSeqPixFromJsonFile() -> [SeqPix] {
     print(">>> try getSeqPixFromJsonFile")
    
    // le fichier SeqPix.json est stocke dans le repertoire Documents du sandbox de l application
    let filename = getDocumentsDirectory().appendingPathComponent("SeqPix.json")
    
    var jsonResult:[SeqPix] = []
    do {
        // lire au format data
        let data = try Data(contentsOf: filename)
        
        // decoder les data sur le schéma de SeqPix
         jsonResult = try JSONDecoder().decode([SeqPix].self, from: data)

        if jsonResult.count > 0 {
            print("Nbre de sequences : \(jsonResult.count)")
            }
        else {
                print("Pas de sequence lue !!!")
        }
            
        }
    catch {
            print("Echec de lecture JSON")
    }
    
    return jsonResult
    
}

