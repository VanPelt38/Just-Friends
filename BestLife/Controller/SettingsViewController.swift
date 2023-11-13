//
//  SettingsViewController.swift
//  BestLife
//
//  Created by Jake Gordon on 03/07/2023.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var settingsTableView: UITableView!
    
    var settingTitles = ["Distance Preferences", "Log Out", "Delete Account"]
    var firebaseID = ""
    private let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settingsTableView.dataSource = self
        settingsTableView.delegate = self
    }
    
    func logOut() {
        
        let confirmLogOutAlert = UIAlertController(title: "", message: "Are you sure you'd like to log out?", preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Yes", style: .default) { alertAction in
            
            do {
                try Auth.auth().signOut()
            } catch let signOutError as NSError {
                print("Error signing out: \(signOutError)")
            }
            if let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") {
                loginVC.modalPresentationStyle = .overFullScreen
                self.present(loginVC, animated: false, completion: nil)
            }
        }
        let nopeAction = UIAlertAction(title: "No", style: .default)
        confirmLogOutAlert.addAction(okayAction)
        confirmLogOutAlert.addAction(nopeAction)
        present(confirmLogOutAlert, animated: true)
    }
    
    func deleteAccount() {
        
        let confirmDeleteAlert = UIAlertController(title: "Are you sure?", message: "All your matches, chats, and other data will be lost.", preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Yes", style: .default) { [self] alertAction in
            
            if let currentUser = Auth.auth().currentUser {
                
                firebaseID = currentUser.uid
                
                Task.init {
                    await self.wipeData()
                    currentUser.delete { error in
                        if let error = error {
                            print("Error deleting user account: \(error)")
                        } else {
                            
                            if let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") {
                                loginVC.modalPresentationStyle = .fullScreen
                                self.present(loginVC, animated: false, completion: nil)
                                let confirmDeleteAlert = UIAlertController(title: "Success!", message: "Your account has been deleted.", preferredStyle: .alert)
                                let okayAction = UIAlertAction(title: "OK", style: .default)
                                confirmDeleteAlert.addAction(okayAction)
                                loginVC.present(confirmDeleteAlert, animated: true)
                            }
                        }
                    }
                }
            }
        }
        let nopeAction = UIAlertAction(title: "No", style: .default)
        confirmDeleteAlert.addAction(okayAction)
        confirmDeleteAlert.addAction(nopeAction)
        present(confirmDeleteAlert, animated: true)
    }
    
    func wipeData() async {
        
        //Delete references to user in other users' collections
        
        let userMatchStatuses = db.collection("users").document(firebaseID).collection("matchStatuses")
        var chatIDS: [String] = []
        var userIDS: [String] = []
        
        do {
            let alluserMatchStatuses = try await userMatchStatuses.getDocuments()
            
            for doc in alluserMatchStatuses.documents {
                let data = doc.data()
                if let userID = data["ID"] as? String, let chatID = data["chatID"] as? String {
                    userIDS.append(userID)
                    chatIDS.append(chatID)
                }
            }
        } catch {
            print(error)
        }
        
        let chatCollection = db.collection("chats")
        
        for id in chatIDS {
            
            do {
                let chatToDelete = chatCollection.document(id)
               try await chatToDelete.delete()
            } catch {
                print("error deleting chat: \(error)")
            }
        }
        
        for id in userIDS {
            let matchReference = db.collection("users").document(id).collection("matchStatuses").document(firebaseID)
            do {
                try await matchReference.delete()
            } catch {
                print("error deleting match matchStatus: \(error)")
            }
        }
        
        // Now delete user's own data
        
        let ownProfileRef = db.collection("users").document(firebaseID)
        do {
            try await ownProfileRef.delete()
        } catch {
            print("error deleting user profile: \(error)")
        }
        
        let statusRef = db.collection("statuses").whereField("userID", isEqualTo: firebaseID)
        do {
            let userStatus = try await statusRef.getDocuments()
            for doc in userStatus.documents {
                let docRef = doc.reference
                do {
                    try await docRef.delete()
                } catch {
                    print("error deleting userStatus: \(error)")
                }
            }
        } catch {
            print("error deleting user profile: \(error)")
        }
        
        // Delete profile pic from storage
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        guard let realm = RealmManager.getRealm() else {return}
        let userProfile = realm.objects(RProfile.self).filter("userID == %@", firebaseID).first
        let imageRef = userProfile?.profilePicRef
        if let safeImageRef = imageRef {
            let storagePath = storageRef.child("images/\(safeImageRef)")
            do {
                try await storagePath.delete()
            } catch {
                print("error deleting image: \(error)")
            }
        }
    }
}

extension SettingsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return settingTitles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = settingTitles[indexPath.row]
        
        cell.contentConfiguration = content
        
        return cell
    }
}

extension SettingsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == 0 {
            performSegue(withIdentifier: "settingsDistanceSeg", sender: self)
        }
        if indexPath.row == 1 {
            logOut()
        }
        if indexPath.row == 2 {
            deleteAccount()
        }
        
    }
    
}
