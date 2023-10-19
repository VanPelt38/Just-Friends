//
//  RRegistration.swift
//  BestLife
//
//  Created by Jake Gordon on 17/10/2023.
//

import Foundation
import RealmSwift

class RRegistration: Object {
    
    @Persisted(primaryKey: true) var id = ""
    @Persisted var profileSetUp = false
}
