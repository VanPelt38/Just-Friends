//
//  RStatus.swift
//  BestLife
//
//  Created by Jake Gordon on 19/10/2023.
//

import Foundation
import RealmSwift

class RStatus: Object {
    
    @Persisted(primaryKey: true) var id = ""
    @Persisted var dateActivity = "none"
    @Persisted var dateTime = "none"
    @Persisted var daterID = "none"
    @Persisted var suitorID = "none"
    @Persisted var suitorName = "none"
    @Persisted var firebaseDocID = "none"
    @Persisted var fcmToken = "none"
    @Persisted var latitude: Double = 0.0
    @Persisted var longitued: Double = 0.0
}
