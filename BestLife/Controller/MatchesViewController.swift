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

class MatchesViewController: UIViewController {

    @IBOutlet weak var matchesTableView: UITableView!
    
    @IBAction func messagesButton(_ sender: UIBarButtonItem) {
    }
    
    var matchesArray: [MatchModel] = []
    var firebaseID = ""
    let db = Firestore.firestore()
    var ownMatch = MatchModel()
    var matchIDForChat = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task.init {
            do {
                try await deleteNotifications()
                try await loadMatches()
            } catch {
                print(error)
            }
            
        }

        matchesTableView.delegate = self
        matchesTableView.register(UINib(nibName: "DatePlanCell", bundle: nil), forCellReuseIdentifier: "datePlanCell")
        matchesTableView.dataSource = self
        
        
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
        
        let pathway = db.collection("users").document(firebaseID).collection("matchStatuses")
        
        do {
            
            let querySnapshot = try await pathway.getDocuments()
            
            for doc in querySnapshot.documents {
                
                let data = doc.data()
                if let name = data["name"] as? String, let age = data["age"] as? String, let gender = data["gender"] as? String, let image = data["imageURL"] as? String, let dateTime = data["time"] as? String, let dateActivity = data["activity"] as? String, let userID = data["ID"] as? String, let accepted = data["accepted"] as? Bool, let fcmToken = data["fcmToken"] as? String {
                    var match = MatchModel(name: name, age: age, gender: gender, imageURL: image, dateActivity: dateActivity, dateTime: dateTime, ID: userID, accepted: accepted, fcmToken: fcmToken
                    )
                    self.matchesArray.append(match)
                }
            }
            
        } catch {
            
            print(error)
        }
        
        print("this is matches count after it's loaded: \(self.matchesArray.count)")
       
        DispatchQueue.main.async {
            
            self.matchesTableView.reloadData()
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
            
            print("segue triggered now, and matchIDforChat is: \(matchIDForChat)")
            
            let destinationVC = segue.destination as! ChatViewController
            destinationVC.firebaseID = firebaseID
            destinationVC.matchID = matchIDForChat
            
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
        
        return matchesArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = matchesTableView.dequeueReusableCell(withIdentifier: "datePlanCell", for: indexPath) as! DatePlanCell
        
        cell.delegate = self
        cell.indexPath = indexPath
        
        if matchesArray[indexPath.row].accepted == true {
            
            cell.acceptedButton.isHidden = true
            cell.rejectedButton.isHidden = true
        }
        
       
        cell.datePlanLabel.text = "\(matchesArray[indexPath.row].name) wants to \(matchesArray[indexPath.row].dateActivity) \(matchesArray[indexPath.row].dateTime)"
        cell.ageLabel.text = matchesArray[indexPath.row].age
        cell.genderLabel.text = matchesArray[indexPath.row].gender
        
        DispatchQueue.main.async {
            
            if let url = URL(string: self.matchesArray[indexPath.row].imageURL) {
                
                do {
                    
                    let data = try Data(contentsOf: url)
                    let image = UIImage(data: data)
                    cell.profilePicture.image = image
                } catch {
                    
                    print("ERROR LOADING PROFILE IMAGE: \(error.localizedDescription)")
                }
            }
        }
        
        return cell
    }
    
    
    
}

extension MatchesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if matchesArray[indexPath.row].accepted == true {
            
            matchIDForChat = matchesArray[indexPath.row].ID
            
            print("just set the matchIDForChat, which is: \(matchIDForChat), about to trigger segue")
            
            performSegue(withIdentifier: "matchesChatSeg", sender: self)
        }
    }
    
}

extension MatchesViewController: CustomTableViewCellDelegate {
    
    
    func customTableViewCellDidTapButton(_ cell: DatePlanCell, indexPath: IndexPath, buttonName: String) async {
        
        if buttonName == "rejectedButton" {
            
            
            let confirmRejectAlert = UIAlertController(title: "Sure?", message: "", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Yes!", style: .default) { [self] alertAction in
                
                let asyncHandler: @convention(block) (UIAlertAction) -> Void = { [self] _ in
                    
                    Task.init {
                        
                        if let currentUser = Auth.auth().currentUser {
                            self.firebaseID = currentUser.uid
                        } else {
                            print("no user is currently signed in")
                        }
                        
                        let currentCollection = db.collection("users").document(firebaseID).collection("matchStatuses")
                        let query = currentCollection.whereField("ID", isEqualTo: matchesArray[indexPath.row].ID)
                        
                        do {
                            let querySnapshot = try await query.getDocuments()
                            
                            for doc in querySnapshot.documents {
                                print("this is one match status")
                                try await doc.reference.delete()
                            }
                        } catch {
                            print(error)
                        }
                        
                        DispatchQueue.main.async { [self] in
                            matchesArray.remove(at: indexPath.row)
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
            
            
            let confirmAcceptAlert = UIAlertController(title: "Sure?", message: "", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Yes!", style: .default) { [self] alertAction in
                
                
                let chatID = IDgenerator()
                
                let myFunctions = Functions.functions()
                
                
                let data: [String: Any] = [
                    "suitor": matchesArray[indexPath.row].fcmToken,
                    "suitee": self.firebaseID
                ]
   
               
                myFunctions.httpsCallable("confirmMatch").call(data) { result, error in
                    
                        if let error = error {
                            print("Error calling function: \(error.localizedDescription)")
                        } else if let result = result {
                            print("Function result: \(result.data ?? "")")
                        }
                    }
                
                let asyncHandler: @convention(block) (UIAlertAction) -> Void = { [self] _ in
                    
                    Task.init {
                        
                        if let currentUser = Auth.auth().currentUser {
                            self.firebaseID = currentUser.uid
                        } else {
                            print("no user is currently signed in")
                        }
                        
                        try await db.collection("users").document(firebaseID).collection("matchStatuses").document(matchesArray[indexPath.row].ID).updateData([
                            "accepted" : true,
                            "chatID" : chatID
                        ])
                        
                        let chatMatchName = matchesArray[indexPath.row].name
                        let chatMatchID = matchesArray[indexPath.row].ID
                        
                        try await db.collection("chats").document(chatID).collection("userDetails").document(chatID).setData([
                            "userNames" : [chatMatchName, ownMatch.name],
                            "userIDs" : [chatMatchID, firebaseID]
                        ])
                        
                        
                        db.collection("users").document(matchesArray[indexPath.row].ID).collection("matchStatuses").document(firebaseID).setData([
                            "name" : ownMatch.name,
                            "imageURL" : ownMatch.imageURL,
                            "activity" : ownMatch.dateActivity,
                            "time" : ownMatch.dateTime,
                            "ID" : ownMatch.ID,
                            "age" : ownMatch.age,
                            "gender" : ownMatch.gender,
                            "accepted" : true,
                            "fcmToken" : ownMatch.fcmToken,
                            "chatID" : chatID
                        ]) { err in
                            if let err = err {
                                print("error writing doc: \(err)")
                            } else {
                                print("doc written successfully.")
                            }
                        }
                        
                        var daterID = matchesArray[indexPath.row].ID
                        
                        try await addNotification(daterID: daterID, firebaseID: firebaseID)
  
                        
                        DispatchQueue.main.async { [self] in
                            matchesArray[indexPath.row].accepted = true
                            matchesTableView.reloadData()
                        }
                    }
                }
                
                asyncHandler(alertAction)
                
                
                performSegue(withIdentifier: "matchesChatSeg", sender: self)
                
            }
            
            let nopeAction = UIAlertAction(title: "No", style: .default)
            confirmAcceptAlert.addAction(okayAction)
            confirmAcceptAlert.addAction(nopeAction)
            present(confirmAcceptAlert, animated: true)
            
        }
        
    
    }

}
