//
//  CustomCommentCell.swift
//  BestLife
//
//  Created by Jake Gordon on 28/12/2023.
//

import Foundation
import UIKit
import MessageKit

open class CustomCommentCell: TextMessageCell {
    
    var indexPath: IndexPath?
    
    open override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)

        messageLabel.textColor = .black
      
        messageContainerView.addSubview(messageLabel)
    }
}
