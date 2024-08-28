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
    @Persisted var profilePicRef = ""
    @Persisted var profilePicURL = ""
    @Persisted var town: String?
    @Persisted var occupation: String?
    @Persisted var summary: String?
    @Persisted var interests: List<String>
    @Persisted var fcmToken = ""
    
    override static func primaryKey() -> String? {
        return "userID"
    }
}

