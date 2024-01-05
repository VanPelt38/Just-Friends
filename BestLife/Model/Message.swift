//
//  Message.swift
//  BestLife
//
//  Created by Jake Gordon on 28/12/2023.
//

import Foundation
import MessageKit

class Message: MessageType {
    
    var sender: MessageKit.SenderType
    
    var messageId: String
    
    var sentDate: Date
    var message: String = ""
    var kind: MessageKit.MessageKind
    
    
    init(id: String, date: Date, message: String, sender: Sender) {
        
        self.messageId = id
        self.sentDate = date
        self.message = message
        self.kind = .text(message)
        self.sender = sender
    }
}
