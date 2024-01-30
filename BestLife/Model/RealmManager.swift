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
            schemaVersion: 6) { migration, oldSchemaVersion in
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
                if oldSchemaVersion < 4 {
                    migration.enumerateObjects(ofType: RExpiringMatch.className()) { oldObject, newObject in
                        newObject?["ownUserID"] = ""
                    }
                }
                if oldSchemaVersion < 5 {
                    migration.enumerateObjects(ofType: RProfile.className()) { oldObject, newObject in
                        newObject?["profilePicURL"] = ""
                    }
                }
                if oldSchemaVersion < 6 {
                    migration.enumerateObjects(ofType: RStatus.className()) { oldObject, newObject in
                        newObject?["timeStamp"] = nil
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
