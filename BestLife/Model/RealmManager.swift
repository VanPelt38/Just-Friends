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
        
        let config = Realm.Configuration(
            schemaVersion: 3) { migration, oldSchemaVersion in
                if oldSchemaVersion < 2 {
                    migration.enumerateObjects(ofType: RMatchModel.className()) { oldObject, newObject in
                        newObject?["ownUserID"] = ""
                        newObject?["profilePicRef"] = ""
                    }
                }
                if oldSchemaVersion < 3 {
                    migration.enumerateObjects(ofType: RProfile.className()) { oldObject, newObject in
                        newObject?["profilePicRef"] = ""
                    }
                }
            }
        
        do {
            let realm = try! Realm(configuration: config)
            return realm
        } catch {
            print("error getting realm: \(error)")
        }
    }
}
