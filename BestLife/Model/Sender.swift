//
//  Sender.swift
//  BestLife
//
//  Created by Jake Gordon on 28/12/2023.
//

import Foundation
import MessageKit

class Sender: SenderType {
    
    var senderId: String
    var displayName: String
    
    init(name: String, id: String) {
        self.senderId = name
        self.displayName = id
    }
}
