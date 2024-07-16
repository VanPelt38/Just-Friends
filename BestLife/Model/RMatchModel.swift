//
//  RMatchModel.swift
//  BestLife
//
//  Created by Jake Gordon on 28/09/2023.
//

import Foundation
import RealmSwift

class RMatchModel: Object {
    
    @Persisted(primaryKey: true) var id = ""
    @Persisted var name = "none"
    @Persisted var age = 0
    @Persisted var gender = "none"
    @Persisted var imageURL = "none"
    @Persisted var dateActivity = "none"
    @Persisted var dateTime = "none"
    @Persisted var userID = "none"
    @Persisted var accepted = false
    @Persisted var fcmToken = "none"
    @Persisted var chatID = "none"
    @Persisted var ownUserID = "none"
    @Persisted var town: String?
    @Persisted var occupation: String?
    @Persisted var summary: String?
    @Persisted var interests: List<String>
    @Persisted var distanceAway = 0
}
