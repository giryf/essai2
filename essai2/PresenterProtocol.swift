//
//  PresenterProtocol.swift
//  essai2
//
//  Created by Frederic GIRY on 04/02/2020.
//  Copyright © 2020 FabasGalaxy. All rights reserved.
//

import Foundation

protocol TimeReqProtocol: class {
    func resetUI(status: Bool)
    func updateUI(serverMS: Int, localMS:Int)
}
