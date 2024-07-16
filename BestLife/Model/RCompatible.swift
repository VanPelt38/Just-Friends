//
//  RCompatible.swift
//  BestLife
//
//  Created by Jake Gordon on 24/06/2024.
//

import Foundation
import RealmSwift

class RCompatible: Object {
    
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
    @Persisted var ownUserID = ""
    @Persisted var distanceAway = 0
}
