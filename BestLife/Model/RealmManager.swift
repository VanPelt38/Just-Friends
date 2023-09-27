//
//  Realm.swift
//  BestLife
//
//  Created by Jake Gordon on 24/09/2023.
//

import Foundation
import RealmSwift

class RealmManager {
    
    class func getRealm() -> Realm? {
        do {
            let realm = try! Realm()
            return realm
        } catch {
            print("error getting realm: \(error)")
        }
    }
}
