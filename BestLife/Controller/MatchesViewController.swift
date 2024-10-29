//
//  MatchesViewController.swift
//  BestLife
//
//  Created by Jake Gordon on 15/12/2022.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFunctions
import Kingfisher
import RealmSwift

class MatchesViewController: BaseViewController {

    @IBOutlet weak var matchesTableView: UITableView!
    
    @IBOutlet weak var noConnectionsYetLabel: UILabel!
    @IBAction func messagesButton(_ sender: UIBarButtonItem) {
    }
    
    var matchesArray: Results<RMatchModel>?
    var firebaseID = ""
    let db = Firestore.firestore()
    var ownMatch = MatchModel()
    var matchIDForChat = ""
    var passedMatchID: String?
    var matchIDsForDeletion: [String] = []
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        noConnectionsYetLabel.isHidden = true
        noConnectionsYetLabel.translatesAutoresizingMaskIntoConstraints = false
        let centerXConstraint = NSLayoutConstraint(item: noConnectionsYetLabel,
                                                   attribute: .centerX,
                                                   relatedBy: .equal,
                                                   toItem: view,
                                                   attribute: .centerX,
                                                   multiplier: 1.0,
                                                   constant: 0.0)
        let centerYConstraint = NSLayoutConstraint(item: noConnectionsYetLabel,
                                                   attribute: .centerY,
                                                   relatedBy: .equal,
                                                   toItem: view,
                                                   attribute: .centerY,
                                                   multiplier: 1.0,
                                                   constant: 0.0)
        let widthConstraint = NSLayoutConstraint(item: noConnectionsYetLabel,
                                                 attribute: .width,
                                                 relatedBy: .equal,
                                                 toItem: nil,
                                                 attribute: .notAnAttribute,
                                                 multiplier: 1.0,
                                                 constant: 330.0)  // Adjust as needed

        let heightConstraint = NSLayoutConstraint(item: noConnectionsYetLabel,
                                                  attribute: .height,
                                                  relatedBy: .equal,
                                                  toItem: nil,
                                                  attribute: .notAnAttribute,
                                                  multiplier: 1.0,
                                                  constant: 170.0)
        
        view.addConstraints([centerXConstraint, centerYConstraint, widthConstraint, heightConstraint])
        
        matchesTableView.delegate = self
        matchesTableView.register(UINib(nibName: "DatePlanCell", bundle: nil), forCellReuseIdentifier: "datePlanCell")
        matchesTableView.dataSource = self
        
          loadAllMatches()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.hidesBackButton = true
        if let navController = navigationController {
            if navController.viewControllers.first != self {
                navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "arrow25"), style: .plain, target: self, action: #selector(popVC))
            }
        }
    }
    
    @objc func popVC() {
        navigationController?.popViewController(animated: true)
    }
    
    func loadAllMatches() {
        
        Task.init {
                await loadMatches()
                await deleteNotifications()
                await grabNewMatches()
                await removeDeletedMatches()
                await loadUserDetails()
        }
    }
    
    func removeDeletedMatches() async {
 
        guard let realm = RealmManager.getRealm() else {return}
      
        for (index, match) in matchesArray!.enumerated() {
            if !matchIDsForDeletion.contains(match.userID) {
                try! realm.write {
                    if let missingMatch = realm.object(ofType: RMatchModel.self, forPrimaryKey: match.id) {
                        realm.delete(missingMatch)
                    }
                }
            }
        }
        DispatchQueue.main.async { [self] in
            matchesTableView.reloadData()
            if matchesArray!.isEmpty {
                noConnectionsYetLabel.isHidden = false
            }
        }
    }
    
    func grabNewMatches() async {
        
        if let currentUser = Auth.auth().currentUser {
            firebaseID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
        var currentMatchIDs: [String] = []
        for match in matchesArray! {
            currentMatchIDs.append(match.userID)
        }
        matchIDsForDeletion.removeAll()
        let query = db.collection("users").document(firebaseID).collection("matchStatuses")
        guard let realm = RealmManager.getRealm() else {return}
        do {
            let querySnapshot = try await query.getDocuments()
            for doc in querySnapshot.documents {
                let data = doc.data()
                if let deleteID = data["ID"] as? String {
                    matchIDsForDeletion.append(deleteID)
                }
                if !currentMatchIDs.contains(data["ID"] as? String ?? "none") {
                    
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
                            if let distanceAway = data["distanceAway"] as? Int {
                                realmMatch.distanceAway = distanceAway
                            }
                            realm.add(realmMatch, update: .all)
                            
                            DispatchQueue.main.async {
                                self.matchesTableView.reloadData()
                            }
                        }
                    }
                }
            }
        } catch {
            print("error downloading matches: \(error)")
        }
    }
    
    func loadUserDetails() async {
        
        if let currentUser = Auth.auth().currentUser {
            firebaseID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
                
                guard let realm = RealmManager.getRealm() else {return}
        if let realmProfile = realm.objects(RProfile.self).filter("userID == %@", firebaseID).first {
            
            var myProfile = MatchModel()
            myProfile.name = realmProfile.name
            myProfile.age = realmProfile.age
            myProfile.gender = realmProfile.gender
            myProfile.imageURL = realmProfile.profilePicURL
            myProfile.ID = realmProfile.userID
            myProfile.chatID = ""
            myProfile.fcmToken = realmProfile.fcmToken
            
            if let realmStatus = realm.object(ofType: RStatus.self, forPrimaryKey: firebaseID) {
                myProfile.dateActivity = realmStatus.dateActivity
                myProfile.dateTime = realmStatus.dateTime
                myProfile.fcmToken = realmStatus.fcmToken
            }
                        ownMatch = myProfile
                }
    }
    
    func deleteNotifications() async {

        if let currentUser = Auth.auth().currentUser {
            firebaseID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
            
            let currentCollection = db.collection("users").document(firebaseID).collection("matchNotifications")

            do {
                let querySnapshot = try await currentCollection.getDocuments()
                
                for doc in querySnapshot.documents {
                     
                    try await currentCollection.document(doc.documentID).delete()
                    }
            } catch {
                print(error)
            }
    }
    
    func loadMatches() async {

        if let currentUser = Auth.auth().currentUser {
            firebaseID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
        
        guard let realm = RealmManager.getRealm() else {return}
        
        matchesArray = realm.objects(RMatchModel.self).filter("ownUserID == %@", firebaseID)

        DispatchQueue.main.async {
            if self.matchesArray!.isEmpty {
                self.noConnectionsYetLabel.isHidden = false
            }
            self.matchesTableView.reloadData()
        }
    }
    
    func deleteMatch(indexPath: Int) async {
        
        let userID2Delete = matchesArray![indexPath].userID
        let chatID2Delete = matchesArray![indexPath].chatID
        
        if let currentUser = Auth.auth().currentUser {
            firebaseID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
        
        guard let realm = RealmManager.getRealm() else {return}
        
        let userCopy = db.collection("users").document(firebaseID).collection("matchStatuses").document(matchesArray![indexPath].userID)
        
        do {
           try await userCopy.delete()
        } catch {
            print(error)
        }
       
        if let matchToDelete = realm.object(ofType: RMatchModel.self, forPrimaryKey: matchesArray![indexPath].id) {
                try! realm.write {
                    realm.delete(matchToDelete)
                }
            
        }
        
        let matchCopy = db.collection("users").document(userID2Delete).collection("matchStatuses").document(firebaseID)

        do {
           try await matchCopy.delete()
        } catch {
            print(error)
        }
        
        let chatRef = db.collection("chats").document(chatID2Delete)
 
        do {
            try await chatRef.delete()
        } catch {
            print("error deleting chat: \(error)")
        }
        
        let realmChats = realm.objects(RChatDoc.self)
        for chat in realmChats {
            if chat.chatID == chatID2Delete {
                try! realm.write {
                    realm.delete(chat)
                }
            }
        }
       
           }
    
    
    func addNotification(daterID: String, firebaseID: String) async {
        
        var suitorIDs: [String] = []

            let currentCollection = db.collection("users").document(daterID).collection("matchNotifications")

            do {
                let querySnapshot = try await currentCollection.getDocuments()
                
                for doc in querySnapshot.documents {
                        let data = doc.data()
                        if let suitorID = data["suitorID"] as? String {
  
                            suitorIDs.append(suitorID)
   
                        }
                    }

                
                if !suitorIDs.contains(firebaseID) {

                    currentCollection.addDocument(data:
                    ["suitorID" : firebaseID]
                    ) { err in
                        if let err = err {
                            print("error writing doc: \(err)")
                        } else {
                            print("doc written successfully.")
                        }
                    }

                }
                
                
            } catch {
                print(error)
            }
        
            }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "matchesChatSeg" {
            
            let destinationVC = segue.destination as! MessageViewController
            destinationVC.firebaseID = firebaseID
            destinationVC.matchID = matchIDForChat
            destinationVC.ownMatch = ownMatch
            destinationVC.sender = Sender(name: ownMatch.ID, id: ownMatch.name)
            destinationVC.hidesBottomBarWhenPushed = true
        }
        
        if segue.identifier == "matchesMatchProfileSeg" {
            
            let destinationVC = segue.destination as! MatchProfileViewController
            
            destinationVC.matchID = self.passedMatchID
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

}


extension MatchesViewController: UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let defMatchesArray = matchesArray {
            return defMatchesArray.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = matchesTableView.dequeueReusableCell(withIdentifier: "datePlanCell", for: indexPath) as! DatePlanCell
        noConnectionsYetLabel.isHidden = true
        cell.delegate = self
        cell.indexPath = indexPath
        cell.acceptedButton.isHidden = true
        cell.rejectedButton.isHidden = true
        
        cell.profilePicture.layer.cornerRadius = cell.profilePicture.frame.width / 2
        cell.profilePicture.clipsToBounds = true
        
        if matchesArray![indexPath.row].accepted == false {
            
            cell.acceptedButton.isHidden = false
            cell.rejectedButton.isHidden = false
        }
        
        cell.distanceAwayLabel.text = matchesArray![indexPath.row].distanceAway >= 1 ? "\(matchesArray![indexPath.row].distanceAway) km away" : "1 km away"
        
        cell.datePlanLabel.text = matchesArray![indexPath.row].dateTime == "none" ? matchesArray![indexPath.row].name : "\(matchesArray![indexPath.row].name) wants to \(matchesArray![indexPath.row].dateActivity) \(matchesArray![indexPath.row].dateTime)"
        cell.ageLabel.text = String(matchesArray![indexPath.row].age)
        cell.genderLabel.image = UIImage(named: "big male")
        if matchesArray![indexPath.row].gender == "female" {
            cell.genderLabel.image = UIImage(named: "big female")
        }
       
        
        DispatchQueue.main.async {
            
            if let url = URL(string: self.matchesArray![indexPath.row].imageURL) {
                
                    cell.profilePicture.kf.setImage(with: url)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            let confirmDeleteAlert = UIAlertController(title: "Are you sure?", message: "", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Yes", style: .default) { [self] alertAction in
                    
                    Task.init {

                        await deleteMatch(indexPath: indexPath.row)

                        matchesTableView.deleteRows(at: [indexPath], with: .fade)
                        
                        DispatchQueue.main.async { [self] in

                            if matchesArray!.count == 0 {
                                noConnectionsYetLabel.isHidden = false
                            }
                            self.matchesTableView.reloadData()
                        }
                    }
            }
            
            let nopeAction = UIAlertAction(title: "No", style: .default)
            confirmDeleteAlert.addAction(okayAction)
            confirmDeleteAlert.addAction(nopeAction)
            present(confirmDeleteAlert, animated: true)
            }
        }
}

extension MatchesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 150.0
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if matchesArray![indexPath.row].accepted == true {
            
            matchIDForChat = matchesArray![indexPath.row].id
            
            performSegue(withIdentifier: "matchesChatSeg", sender: self)
        }
    }
    
}

extension MatchesViewController: CustomTableViewCellDelegate {
    
    
    func customTableViewCellDidTapButton(_ cell: DatePlanCell, indexPath: IndexPath, buttonName: String) async {
        
        if buttonName == "rejectedButton" {
            
            
            let confirmRejectAlert = UIAlertController(title: "Are you sure?", message: "", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Yes", style: .default) { [self] alertAction in
                
                let asyncHandler: @convention(block) (UIAlertAction) -> Void = { [self] _ in
                    
                    Task.init {
                        
                        if let currentUser = Auth.auth().currentUser {
                            self.firebaseID = currentUser.uid
                        } else {
                            print("no user is currently signed in")
                        }
                        
                        let currentCollection = db.collection("users").document(firebaseID).collection("matchStatuses")
                        let query = currentCollection.whereField("ID", isEqualTo: matchesArray![indexPath.row].userID)
                        
                        do {
                            let querySnapshot = try await query.getDocuments()
                            
                            for doc in querySnapshot.documents {
                                try await doc.reference.delete()
                            }
                        } catch {
                            print(error)
                        }
                        
                        guard let realm = RealmManager.getRealm() else {return}
                        if let matchToDelete = realm.object(ofType: RMatchModel.self, forPrimaryKey: matchesArray![indexPath.row].id) {
                            try! realm.write {
                                realm.delete(matchToDelete)
                            }
                        }
                        
                        DispatchQueue.main.async { [self] in

                            if matchesArray!.count == 0 {
                                noConnectionsYetLabel.isHidden = false
                            }
                            matchesTableView.reloadData()
                        }
                    }
                }
                
                asyncHandler(alertAction)
                
            }
            
            let nopeAction = UIAlertAction(title: "No", style: .default)
            confirmRejectAlert.addAction(okayAction)
            confirmRejectAlert.addAction(nopeAction)
            present(confirmRejectAlert, animated: true)
            
        } else if buttonName == "acceptedButton" {
            
            
            let confirmAcceptAlert = UIAlertController(title: "Are you sure?", message: "", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Yes", style: .default) { [self] alertAction in
                
                
                let chatID = IDgenerator()
                
                matchIDForChat = matchesArray![indexPath.row].id
                let myFunctions = Functions.functions()
                
                let data: [String: Any] = [
                    "suitor": matchesArray![indexPath.row].fcmToken,
                    "suitee": self.firebaseID,
                    "suiteeName": ownMatch.name
                ]
   
               
                myFunctions.httpsCallable("confirmMatch").call(data) { result, error in
                    
                        if let error = error {
                            print("Error calling function: \(error.localizedDescription)")
                        } else if let result = result {
                            print("Function result: \(result.data)")
                        }
                    }
                
                let asyncHandler: @convention(block) (UIAlertAction) -> Void = { [self] _ in
                    
                    Task.init {
                        
                        if let currentUser = Auth.auth().currentUser {
                            self.firebaseID = currentUser.uid
                        } else {
                            print("no user is currently signed in")
                        }
                        
                        try await db.collection("users").document(firebaseID).collection("matchStatuses").document(matchesArray![indexPath.row].userID).updateData([
                            "accepted" : true,
                            "chatID" : chatID
                        ])
                      
                        guard let realm = RealmManager.getRealm() else {return}
                        try! realm.write {
 
                            if let matchToUpdate = realm.object(ofType: RMatchModel.self, forPrimaryKey: matchesArray![indexPath.row].id) {
                                matchToUpdate.accepted = true
                                matchToUpdate.chatID = chatID
                            }
                            
                        }
                        
                        let chatMatchName = matchesArray![indexPath.row].name
                        let chatMatchID = matchesArray![indexPath.row].userID
                        
                        try await db.collection("chats").document(chatID).collection("userDetails").document(chatID).setData([
                            "userNames" : [chatMatchName, ownMatch.name],
                            "userIDs" : [chatMatchID, firebaseID]
                        ])
                        
                        db.collection("users").document(matchesArray![indexPath.row].userID).collection("matchStatuses").document(firebaseID).setData([
                            "name" : ownMatch.name,
                            "imageURL" : ownMatch.imageURL,
                            "activity" : ownMatch.dateActivity,
                            "time" : ownMatch.dateTime,
                            "ID" : ownMatch.ID,
                            "age" : ownMatch.age,
                            "gender" : ownMatch.gender,
                            "accepted" : true,
                            "fcmToken" : ownMatch.fcmToken,
                            "chatID" : chatID,
                            "realmID" : UUID().uuidString,
                            "ownUserID" : matchesArray![indexPath.row].userID,
                            "distanceAway" : matchesArray![indexPath.row].distanceAway
                        ]) { err in
                            if let err = err {
                                print("error writing doc: \(err)")
                            } else {
                                print("doc written successfully.")
                            }
                        }
                        
                        let daterID = matchesArray![indexPath.row].userID
                        
                        await addNotification(daterID: daterID, firebaseID: firebaseID)
  
                        
                        DispatchQueue.main.async { [self] in
                            try! realm.write {
                                matchesArray![indexPath.row].accepted = true
                                matchesArray![indexPath.row].chatID = chatID
                            }
                            matchesTableView.reloadData()
                            performSegue(withIdentifier: "matchesChatSeg", sender: self)
                        }
                    }    
                }
                
                asyncHandler(alertAction)
                
            }
            
            let nopeAction = UIAlertAction(title: "No", style: .default)
            confirmAcceptAlert.addAction(okayAction)
            confirmAcceptAlert.addAction(nopeAction)
            present(confirmAcceptAlert, animated: true)
            
        } else if buttonName == "viewProfileButton" {

            passedMatchID = matchesArray![indexPath.row].userID
            performSegue(withIdentifier: "matchesMatchProfileSeg", sender: self)
        }
        
    
    }

}
