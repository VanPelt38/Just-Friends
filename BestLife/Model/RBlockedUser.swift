//
//  RBlockedUser.swift
//  BestLife
//
//  Created by Jake Gordon on 06/12/2023.
//

import Foundation
import RealmSwift

class BlockedUser: Object {
    
    @Persisted(primaryKey: true) var id = ""
    @Persisted var blockID = "none"
    @Persisted var userID = "none"
    @Persisted var blockType = "none"
}
