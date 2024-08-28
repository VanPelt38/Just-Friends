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
            schemaVersion: 9) { migration, oldSchemaVersion in
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
                if oldSchemaVersion < 7 {
                    migration.enumerateObjects(ofType: RProfile.className()) { oldObject, newObject in
                        newObject?["town"] = nil
                        newObject?["occupation"] = nil
                        newObject?["summary"] = nil
                        newObject?["interests"] = List<String>()
                    }
                    migration.enumerateObjects(ofType: RMatchModel.className()) { oldObject, newObject in
                        newObject?["town"] = nil
                        newObject?["occupation"] = nil
                        newObject?["summary"] = nil
                        newObject?["interests"] = List<String>()
                    }
                }
                if oldSchemaVersion < 7 {
                    migration.enumerateObjects(ofType: RMatchModel.className()) { oldObject, newObject in
                        newObject?["distanceAway"] = 0
                    }
                }
                if oldSchemaVersion < 9 {
                    migration.enumerateObjects(ofType: RProfile.className()) { oldObject, newObject in
                        newObject?["fcmToken"] = ""
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
