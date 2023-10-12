//
//  ViewController.swift
//  BestLife
//
//  Created by Jake Gordon on 05/12/2022.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import Kingfisher

class HomeViewController: UIViewController {

    @IBOutlet weak var helloUser: UILabel!
    var firebaseID: String?
    @IBOutlet weak var profilePicture: UIImageView!
    
    private let db = Firestore.firestore()
    var chatIDs: [String] = []
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        loadLocalProfile()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        loadAllUserData()
        setDistancePreference()
        
        
        if let tabBarController = self.tabBarController {


            if let tabItems = tabBarController.tabBar.items {

                let varTabItems = tabItems

                let firstTabBarItem = varTabItems[0]
                firstTabBarItem.image = UIImage(systemName: "house.fill")
              
                let secondTabBarItem = varTabItems[1]
                secondTabBarItem.image = UIImage(systemName: "mail")

                let thirdTabBarItem = varTabItems[2]
                thirdTabBarItem.image = UIImage(systemName: "gearshape")

            }
        }
       
        let userID = IDgenerator()
  
        saveID(userID: userID)
    }
    
    @IBAction func profilePressed(_ sender: UIButton) {
        
        performSegue(withIdentifier: "homeProfileSeg", sender: self)
    }
    
    func setDistancePreference() {
        
        if UserDefaults.standard.value(forKey: "distancePreference") == nil {
            UserDefaults.standard.set(10000, forKey: "distancePreference")
        }
    }
    
    func IDgenerator() -> String {
        
        let len = 12
        let pswdChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!@£$%^&*()"
        let randomPass = String((0..<len).compactMap{ _ in
            pswdChars.randomElement()
        })
        
        return randomPass
    }
    
    func saveID(userID: String) {
        
        if UserDefaults.standard.object(forKey: "uniqueID") == nil {
            
            UserDefaults.standard.set(userID, forKey: "uniqueID")
        }
        
    }
    
    func loadLocalProfile() {
        
        guard let realm = RealmManager.getRealm() else {return}
        
                if let profile = realm.objects(RProfile.self).filter("userID == %@", firebaseID).first {
                    DispatchQueue.main.async {
                        self.helloUser.text = "Hi \(profile.name)!"
                                if let picture = profile.picture {
                                    let image = UIImage(data: picture)
                                    self.profilePicture.image = image
                                }
                    }
                    } else {
                        print("profile couldn't be found.")
                    }
    }
    
    func loadAllUserData() {
        
        if let currentUser = Auth.auth().currentUser {
            firebaseID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
        
        Task.init {
            await loadProfile()
            await loadMatches()
            await loadExpiringRequests()
            await loadChats()
        }
    }
    
    
    func loadExpiringRequests() async {
        
        guard let realm = RealmManager.getRealm() else {return}
        if let safeID = firebaseID {
           
            let pathway = db.collection("users").document(safeID).collection("expiringRequests")
            
            do {
                
                let querySnapshot = try await pathway.getDocuments()
                
                for doc in querySnapshot.documents {
                    
                    let data = doc.data()
                    if let timeStamp = data["timeStamp"] as? Timestamp, let userID = data["ID"] as? String {
                        
                        try! realm.write {
                            
                            var realmExpiringMatch = RExpiringMatch()
                            realmExpiringMatch.id = doc.documentID
                            realmExpiringMatch.userID = userID
                            realmExpiringMatch.timeStamp = timeStamp.dateValue()
                            realm.add(realmExpiringMatch, update: .modified)
                        }
                        
                    }
                }
                
            } catch {
                
                print("error downloading expired matches: \(error)")
            }
        }
    }
    
    func loadChats() async {
        
        guard let realm = RealmManager.getRealm() else {return}
        if let safeID = firebaseID {
            
            for chatID in chatIDs {
                
                let pathway = db.collection("chats").document(chatID).collection("messages")
                
                do {
                    let newChats = try await pathway.getDocuments()
                    
                    for chat in newChats.documents {
                        let data = chat.data()
                        if let timeStamp = data["timeStamp"] as? Timestamp, let userID = data["ID"] as? String, let message = data["message"] as? String {
                            
                            try! realm.write {
                                
                                var realmMessage = RChatDoc()
                                realmMessage.id = chat.documentID
                                realmMessage.message = message
                                realmMessage.timeStamp = timeStamp.dateValue()
                                realmMessage.userID = userID
                                realm.add(realmMessage, update: .all)
                            }
                        }
                    }
                    
                } catch {
                    print("error grabbing chat: \(error)")
                }
            }
        }
    }
    
    func loadProfile() async {
        
        guard let realm = RealmManager.getRealm() else {return}

        let currentCollection = db.collection("users").document(firebaseID!).collection("profile")
        let query = currentCollection.whereField("userID", isEqualTo: firebaseID)
        
        do {
           let querySnapshot = try await query.getDocuments()

                for doc in querySnapshot.documents {

                    let data = doc.data()
                    if let age = data["age"] as? Int, let gender = data["gender"] as? String, let name = data["name"] as? String, let picture = data["picture"] as? String, let userID = data["userID"] as? String {

                        DispatchQueue.main.async {

                            self.helloUser.text = "Hi \(name)!"

                            if let url = URL(string:  picture) {

                                do {
                                    let data = try Data(contentsOf: url)
                                    let image = UIImage(data: data)
                                    try! realm.write {
                                    var realmProfile = RProfile()
                                    realmProfile.age = age
                                    realmProfile.gender = gender
                                    realmProfile.name = name
                                    realmProfile.userID = userID
                                    realmProfile.picture = data
                                        realm.add(realmProfile, update: .modified)
                                    }
                                    self.profilePicture.image = image
                                } catch {
                                    print("ERROR LOADING PROFILE IMAGE: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                }
        } catch {
            print("error loading user profile: \(error)")
        }
    }
    
    func loadMatches() async {
        
        guard let realm = RealmManager.getRealm() else {return}
        if let safeID = firebaseID {
            
            let pathway = db.collection("users").document(safeID).collection("matchStatuses")
            
            do {
                
                let querySnapshot = try await pathway.getDocuments()
                
                for doc in querySnapshot.documents {
                    
                    let data = doc.data()
                    if let name = data["name"] as? String, let age = data["age"] as? Int, let gender = data["gender"] as? String, let image = data["imageURL"] as? String, let dateTime = data["time"] as? String, let dateActivity = data["activity"] as? String, let userID = data["ID"] as? String, let accepted = data["accepted"] as? Bool, let fcmToken = data["fcmToken"] as? String, let chatID = data["chatID"] as? String, let realmID = data["realmID"] as? String {
                        
                        try! realm.write {
                            
                            var realmMatch = RMatchModel()
                            realmMatch.name = name
                            realmMatch.age = age
                            realmMatch.gender = gender
                            realmMatch.imageURL = image
                            realmMatch.dateActivity = dateActivity
                            realmMatch.dateTime = dateTime
                            realmMatch.userID = userID
                            realmMatch.accepted = accepted
                            realmMatch.fcmToken = fcmToken
                            realmMatch.chatID = chatID
                            realmMatch.id = realmID
                            realm.add(realmMatch, update: .all)
                        }
                        
                        chatIDs.append(chatID)
                        
                    }
                }
                
            } catch {
                
                print("error downloading matches: \(error)")
            }
        }
    }
    
    @IBAction func createDatePressed(_ sender: UIButton) {
    }
    

}

