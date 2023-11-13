//
//  RExpiringMatch.swift
//  BestLife
//
//  Created by Jake Gordon on 09/10/2023.
//

import Foundation
import RealmSwift

class RExpiringMatch: Object {
    
    @Persisted(primaryKey: true) var id = ""
    @Persisted var timeStamp: Date?
    @Persisted var userID = "none"
    @Persisted var ownUserID = "none"
}
