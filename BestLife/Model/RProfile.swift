//
//  RProfile.swift
//  BestLife
//
//  Created by Jake Gordon on 24/09/2023.
//

import Foundation
import RealmSwift

class RProfile: Object {
    
    @Persisted var age = 0
    @Persisted var gender = ""
    @Persisted var name = ""
    @Persisted var picture: Data?
    @Persisted var userID = ""
    
    override static func primaryKey() -> String? {
        return "userID"
    }
    
}

