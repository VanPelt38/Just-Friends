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
import RealmSwift

class HomeViewController: UIViewController {

    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var makeFriendButton: UIButton!
    @IBOutlet weak var mostCompatibleButton: UIButton!
    
    @IBOutlet weak var buttonToProfileConstraint: NSLayoutConstraint!
    @IBOutlet weak var viewProfileButton: UIButton!
    private let db = Firestore.firestore()
    var chatIDs: [String] = []
    var firebaseID: String?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        loadLocalProfile()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gradientLayer = CAGradientLayer()
        var updatedFrame = self.navigationController!.navigationBar.bounds
        updatedFrame.size.height += 20
        gradientLayer.frame = updatedFrame
        gradientLayer.colors = [UIColor.green.cgColor, UIColor.blue.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0) // vertical gradient start
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0) // vertical gradient end

        UIGraphicsBeginImageContext(gradientLayer.bounds.size)
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        self.navigationController!.navigationBar.setBackgroundImage(image, for: UIBarMetrics.default)

        setUpUI()
        loadLocalProfile()
        loadAllUserData()
        flagProfileSetUpInRealm()
        setDistancePreference()
        
        
        if let tabBarController = self.tabBarController {


            if let tabItems = tabBarController.tabBar.items {

                let varTabItems = tabItems

                let firstTabBarItem = varTabItems[0]
                firstTabBarItem.image = UIImage(systemName: "house.fill")
                firstTabBarItem.title = nil
                firstTabBarItem.imageInsets = UIEdgeInsets(top: 15, left: 0, bottom: 0, right: 0)
              
                let secondTabBarItem = varTabItems[1]
                secondTabBarItem.image = UIImage(systemName: "person.2")

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
    
    @IBAction func mostCompatiblePressed(_ sender: UIButton) {
        performSegue(withIdentifier: "homeCompatibleSeg", sender: self)
    }
    
    
    func setUpUI() {
        
        makeFriendButton.layer.cornerRadius = makeFriendButton.frame.height / 2
        mostCompatibleButton.layer.cornerRadius = mostCompatibleButton.frame.height / 2
        mostCompatibleButton.backgroundColor = UIColor(red: 255/255, green: 204/255, blue: 204/255, alpha: 1.0)
        profilePicSize()
        viewProfileButton.clipsToBounds = true
        viewProfileButton.layer.cornerRadius = viewProfileButton.frame.size.width / 2
        viewProfileButton.tintColor = .black
        let constraint = NSLayoutConstraint(item: viewProfileButton, attribute: .centerY, relatedBy: .equal, toItem: profilePicture, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        self.view.addConstraint(constraint)
        
        navigationItem.hidesBackButton = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        profilePicSize()
    }
    
    func profilePicSize() {
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            
            let size = CGSize(width: self.view.frame.width / 3, height: self.view.frame.width / 3)
            profilePicture.frame.size = size
            profilePicture.frame.origin.x = (self.view.frame.width / 2) - profilePicture.frame.size.width / 2
            profilePicture.frame.origin.y = (self.view.frame.height / 2) - profilePicture.frame.size.height / 2
            profilePicture.clipsToBounds = true
            profilePicture.layer.cornerRadius = profilePicture.frame.size.width / 2
            
            let constraint = NSLayoutConstraint(item: makeFriendButton, attribute: .top, relatedBy: .equal, toItem: viewProfileButton, attribute: .bottom, multiplier: 1.0, constant: 30.0)
            self.view.addConstraint(constraint)
            
        } else {
            
            let size = CGSize(width: self.view.frame.width, height: self.view.frame.width)
            profilePicture.frame.size = size
            profilePicture.frame.origin.y = 0
            profilePicture.frame.origin.x = 0
        }
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
    
    func flagProfileSetUpInRealm() {
        
        guard let realm = RealmManager.getRealm() else {return}
        
        if let safeID = firebaseID {
            
            try! realm.write {
                let realmRegistration = RRegistration()
                realmRegistration.id = safeID
                realmRegistration.profileSetUp = true
                realm.add(realmRegistration, update: .all)
            }
        }
    }
    
    func loadLocalProfile() {
        
        if let currentUser = Auth.auth().currentUser {
            firebaseID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
        
        guard let realm = RealmManager.getRealm() else {return}
 
                if let profile = realm.objects(RProfile.self).filter("userID == %@", firebaseID).first {
                    DispatchQueue.main.async {
                        self.navigationItem.title = "Hi \(profile.name)"
                       
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
            await loadStatus()
            await loadBlockedUsers()
        }
    }
    
    func loadBlockedUsers() async {
        
        guard let realm = RealmManager.getRealm() else {return}
        if let safeID = firebaseID {
           
            let pathway = db.collection("users").document(safeID).collection("blockedUsers")
            
            do {
                
                let querySnapshot = try await pathway.getDocuments()
                
                for doc in querySnapshot.documents {
                    
                    let data = doc.data()
                    if let blockedUserID = data["blockedUserID"] as? String, let blockType = data["blockType"] as? String {
                        
                        try! realm.write {
                            
                            let newBlock = BlockedUser()
                            newBlock.id = doc.documentID
                            newBlock.blockID = blockedUserID
                            newBlock.userID = safeID
                            newBlock.blockType = blockType
                            
                            realm.add(newBlock, update: .all)
                        }
                    }
                }
                
            } catch {
                
                print("error downloading blocked users: \(error)")
            }
        }

    }
    
    func loadStatus() async {
        
        guard let realm = RealmManager.getRealm() else {return}
        if let safeID = firebaseID {
            
            let pathway = db.collection("statuses")
            let query = pathway.whereField("userID", isEqualTo: safeID)
            
            do {
                let querySnapshot = try await query.getDocuments()
                
                for doc in querySnapshot.documents {
                    
                    let data = doc.data()
                    
                    if let dateActivity = data["activity"] as? String, let latitude = data["latitude"] as? Double, let longitude = data["longitude"] as? Double, let time = data["time"] as? String, let timeStamp = data["timeStamp"] as? Timestamp {
                        
//                        let currentTime = Date()
//                        let expiryTime = timeStamp.dateValue().addingTimeInterval(12 * 60 * 60)
//
//                        if currentTime >= expiryTime {
//
//                            try! realm.write {
//                                if let existingStatus = realm.object(ofType: RStatus.self, forPrimaryKey: safeID) {
//                                    realm.delete(existingStatus)
//                                }
//                            }
//
//                            let docID = doc.documentID
//                            let docReff = pathway.document(docID)
//                        
//                            do {
//                                try await docReff.delete()
//                            } catch {
//                                print("error deleting expired match: \(error)")
//                            }
//
//                        } else {
                            
                            try! realm.write {
                                
                                let realmStatus = RStatus()
                                realmStatus.id = safeID
                                realmStatus.dateActivity = dateActivity
                                realmStatus.dateTime = time
                                realmStatus.latitude = latitude
                                realmStatus.longitued = longitude
                                if let fcmToken = data["fcmToken"] as? String {
                                    realmStatus.fcmToken = fcmToken
                                }
                                if let suitorID = data["suitorID"] as? String {
                                    realmStatus.suitorID = suitorID
                                }
                                if let suitorName = data["suitorName"] as? String {
                                    realmStatus.suitorName = suitorName
                                }
                                realmStatus.firebaseDocID = doc.documentID
                                realmStatus.timeStamp = timeStamp.dateValue()
                                realm.add(realmStatus, update: .all)
                            }
//                        }
                    }
                    
                }
                
            } catch {
                print("error getting user status: \(error)")
            }
        }
    }
    
    func loadExpiringRequests() async {
  
        guard let realm = RealmManager.getRealm() else {return}
        if let safeID = firebaseID {
           
            let pathway = db.collection("users").document(safeID).collection("expiringRequests")
            
            do {
                
                let querySnapshot = try await pathway.getDocuments()
                
                for doc in querySnapshot.documents {
                    print("got one")
                    let data = doc.data()
                    if let timeStamp = data["timeStamp"] as? Timestamp, let userID = data["userID"] as? String, let ownUserID = data["ownUserID"] as? String {
                       
                        try! realm.write {
                            
                            let realmExpiringMatch = RExpiringMatch()
                            realmExpiringMatch.id = doc.documentID
                            realmExpiringMatch.userID = userID
                            realmExpiringMatch.timeStamp = timeStamp.dateValue()
                            realmExpiringMatch.ownUserID = ownUserID
                            realm.add(realmExpiringMatch, update: .all)
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
                                
                                let realmMessage = RChatDoc()
                                realmMessage.id = chat.documentID
                                realmMessage.message = message
                                realmMessage.timeStamp = timeStamp.dateValue()
                                realmMessage.userID = userID
                                realmMessage.chatID = chatID
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
                    if let age = data["age"] as? Int, let gender = data["gender"] as? String, let name = data["name"] as? String, let picture = data["picture"] as? String, let userID = data["userID"] as? String, let profilePicRef = data["profilePicRef"] as? String {

                        DispatchQueue.main.async {

                            self.navigationItem.title = "Hi \(name)"
                            
                            if let url = URL(string: picture) {

                                do {
                                    let imageData = try Data(contentsOf: url)
                                    let image = UIImage(data: imageData)
                                    try! realm.write {
                                        let realmProfile = RProfile()
                                    realmProfile.age = age
                                    realmProfile.gender = gender
                                    realmProfile.name = name
                                    realmProfile.userID = userID
                                    realmProfile.picture = imageData
                                        realmProfile.profilePicURL = picture
                                        realmProfile.profilePicRef = profilePicRef
                                        if let town = data["town"] as? String {
                                            realmProfile.town = town
                                        }
                                        if let profession = data["occupation"] as? String {
                                            realmProfile.occupation = profession
                                        }
                                        if let summary = data["summary"] as? String {
                                            realmProfile.summary = summary
                                        }
                                        if let interests = data["interests"] as? [String] {
                                            let interestsList = List<String>()
                                            interests.forEach { interestsList.append($0) }
                                            realmProfile.interests = interestsList
                                        }
                                        realm.add(realmProfile, update: .all)
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
                    if let name = data["name"] as? String, let age = data["age"] as? Int, let gender = data["gender"] as? String, let image = data["imageURL"] as? String, let dateTime = data["time"] as? String, let dateActivity = data["activity"] as? String, let userID = data["ID"] as? String, let accepted = data["accepted"] as? Bool, let fcmToken = data["fcmToken"] as? String, let chatID = data["chatID"] as? String, let realmID = data["realmID"] as? String, let ownUserID = data["ownUserID"] as? String {
                        
                        try! realm.write {
                            
                            let realmMatch = RMatchModel()
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
                            realmMatch.ownUserID = ownUserID
                            if let town = data["town"] as? String {
                                realmMatch.town = town
                            }
                            if let profession = data["occupation"] as? String {
                                realmMatch.occupation = profession
                            }
                            if let summary = data["summary"] as? String {
                                realmMatch.summary = summary
                            }
                            if let interests = data["interests"] as? [String] {
                                let interestsList = List<String>()
                                interests.forEach { interestsList.append($0) }
                                realmMatch.interests = interestsList
                            }
                            if let distanceAway = data["distanceAway"] as? Int {
                                realmMatch.distanceAway = distanceAway
                            }
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

