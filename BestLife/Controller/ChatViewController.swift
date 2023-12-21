//
//  ChatViewController.swift
//  BestLife
//
//  Created by Jake Gordon on 15/12/2022.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseFunctions
import IQKeyboardManagerSwift
import RealmSwift

class ChatViewController: UIViewController {

    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var chatTextField: UITextField!
    
    var firebaseID = ""
    var matchID = ""
    private let db = Firestore.firestore()
    var matchDetails: Results<RMatchModel>?
    var currentMessages: [RChatDoc] = []
    var sortedCurrentMessages: [RChatDoc] = []
    var chatFieldOriginalY: CGFloat = 0.0
    var tableViewOriginalY: CGFloat = 0.0
    var ownMatch = MatchModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let currentTime = Date()

        IQKeyboardManager.shared.disabledDistanceHandlingClasses.append(ChatViewController.self)
        
        currentMessages = []
        sortedCurrentMessages = []
        
        Task.init {
            print("this is the matchid: \(matchID)")
            await loadMatchDetails(matchID)
            print("this is matchd etails after loading them: \(matchDetails![0])")
            await loadChatMessages()
            
            db.collection("chats").document(matchDetails![0].chatID).collection("messages").addSnapshotListener { [self] snapshot, error in
                
                guard let snapshot = snapshot else {
                    print("error fetching snapshot: \(error)")
                    return
                }
                print("we made it this far, and the chatid is: \(matchDetails![0].chatID)")
                if let error = error {
                    
                    print("listener error: \(error.localizedDescription)")
                }
                
                for change in snapshot.documentChanges {
                    
                    if change.type == .added {
                        
                        let documentData = change.document.data()
                        print("but id ont htink we get here?")
                        if let time = documentData["timeStamp"] as? Timestamp, let userID = documentData["ID"] as? String, let message = documentData["message"] as? String {
                            
                            let messageTime = time.dateValue()
                            
                            if messageTime > currentTime && userID != firebaseID {
                                
                                guard let realm = RealmManager.getRealm() else {return}
                           
                                try! realm.write {
                                 
                                    let newMessage = RChatDoc()
                                    newMessage.id = change.document.documentID
                                    newMessage.message = message
                                    newMessage.timeStamp = messageTime
                                    newMessage.userID = userID
                                    newMessage.chatID = matchDetails![0].chatID
                                    realm.add(newMessage)
                                    
                                    currentMessages.append(newMessage)
                                    sortedCurrentMessages = currentMessages.sorted { $0.timeStamp! < $1.timeStamp! }
                                }
                                    chatTableView.reloadData()
                                    scrollToBottom()
                            }
                        }
                        
                    }
                }
                
            }

        }
        
        chatTableView.delegate = self
        chatTableView.dataSource = self
        
        chatTextField.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
  
    }
    
    @IBAction func flagButtonPressed(_ sender: UIBarButtonItem) {
        
        let safetyAlertController = UIAlertController(title: "Is this user behaving inappropriately?", message: nil, preferredStyle: .actionSheet)
        
        let reportUserAction = UIAlertAction(title: "Report User", style: .default) { action in
            
            let reportOptions = ["Inappropriate Content", "Harassment", "Criminal Behaviour", "User is Underage", "User is Fake/Spam/Scammer", "Cancel"]
            let reportAlertController = UIAlertController(title: "Dont worry - your report is anonymous.", message: nil, preferredStyle: .actionSheet)
            for option in reportOptions {
                if option == "Cancel" {
                    
                    let cancelAction2 = UIAlertAction(title: "Cancel", style: .default) { action in
                        reportAlertController.dismiss(animated: true)
                    }
                    reportAlertController.addAction(cancelAction2)
                } else {
                    let reportOptionAction = UIAlertAction(title: option, style: .default) { [self] action in
                        
                        let areYouSureAlert = UIAlertController(title: "Are you sure you'd like to report this user?", message: nil, preferredStyle: .alert)
                        let okayAction = UIAlertAction(title: "Yes", style: .default) { action in
                            
                            Task.init {
                                await addUserReport(userID: firebaseID, userName: ownMatch.name, abuserID: matchDetails![0].userID, abuserName: matchDetails![0].name, reportType: option)
                                let reportSentAlert = UIAlertController(title: "Report Sent Successfully", message: "Thanks for letting us know - our report team will investigate your concern thoroughly.", preferredStyle: .alert)
                                let okayAction2 = UIAlertAction(title: "Okay", style: .default)
                                reportSentAlert.addAction(okayAction2)
                                self.present(reportSentAlert, animated: true)
                            }
                        }
                        let noAction = UIAlertAction(title: "No", style: .default)
                        areYouSureAlert.addAction(okayAction)
                        areYouSureAlert.addAction(noAction)
                        self.present(areYouSureAlert, animated: true)
                    }
                    reportAlertController.addAction(reportOptionAction)
                }
            }
            safetyAlertController.dismiss(animated: true)
            self.present(reportAlertController, animated: true)
        }
        let blockUserAction = UIAlertAction(title: "Block User", style: .default) { action in
            
            
            let areYouSureAlert = UIAlertController(title: "Are you sure you'd like to block this user?", message: "They will no longer appear in your friends lists, and will be unable to see you either.", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Yes", style: .default) { [self] action in
                
                Task.init {
                    let newBlockID = await self.addBlockedUser(blockedUserID: (matchDetails?[0].userID)!)
                    await self.addSelfToBlockedUserStore(blockedUserID: matchDetails![0].userID)
                    
                    guard let realm = RealmManager.getRealm() else {return}
                    
                    try! realm.write {
                        
                        let newBlock = BlockedUser()
                        newBlock.id = newBlockID
                        newBlock.blockID = matchDetails![0].userID
                        newBlock.userID = firebaseID
                        newBlock.blockType = "blocked"
                        realm.add(newBlock)
                    }
                    
                    await self.wipeBlockedUserData()
                    
                    let blockSuccessfulAlert = UIAlertController(title: "Success", message: "You will no longer be able to interact with this user.", preferredStyle: .alert)
                    let okayAction2 = UIAlertAction(title: "Okay", style: .default) { action in
                        navigationController?.popViewController(animated: true)
                    }
                    blockSuccessfulAlert.addAction(okayAction2)
                    self.present(blockSuccessfulAlert, animated: true)
                }
            }
            let noAction = UIAlertAction(title: "No", style: .default)
            areYouSureAlert.addAction(okayAction)
            areYouSureAlert.addAction(noAction)
            self.present(areYouSureAlert, animated: true)
            
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { action in
            safetyAlertController.dismiss(animated: true)
        }
        safetyAlertController.addAction(reportUserAction)
        safetyAlertController.addAction(blockUserAction)
        safetyAlertController.addAction(cancelAction)
        self.present(safetyAlertController, animated: true)
    }
    
    func addUserReport(userID: String, userName: String, abuserID: String, abuserName: String, reportType: String) async {
        
        do {
            let docRef = try await db.collection("userReports").addDocument(data:
       [
      "userID" : userID,
      "userName" : userName,
      "abuserID" : abuserID,
      "abuserName" : abuserName,
      "reportType" : reportType
     ]
            )
        } catch {
            print("error: \(error)")
        }
        
    }
    
    func addBlockedUser(blockedUserID: String) async -> String {
        
        var docID = ""
        
        do {
            let docRef = try await db.collection("users").document(firebaseID).collection("blockedUsers").addDocument(data:
       [
      "blockedUserID" : blockedUserID,
      "blockType" : "blocked"
     ]
            )
            docID = docRef.documentID
        } catch {
            print("error: \(error)")
        }
        return docID
    }
    
    func addSelfToBlockedUserStore(blockedUserID: String) async {
        
        do {
            let docRef = try await db.collection("users").document(blockedUserID).collection("blockedUsers").addDocument(data:
       [
      "blockedUserID" : firebaseID,
      "blockType" : "blocker"
     ]
            )
        } catch {
            print("error: \(error)")
        }

    }
    
    func wipeBlockedUserData() async {
        
        if let currentUser = Auth.auth().currentUser {
            firebaseID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
        
        let matchUserID = matchDetails![0].userID
        let userChatID = matchDetails![0].chatID
        
        guard let realm = RealmManager.getRealm() else {return}
        
        let userCopy = db.collection("users").document(firebaseID).collection("matchStatuses").document(matchUserID)
        
        do {
           try await userCopy.delete()
        } catch {
            print(error)
        }
        print("and this is matchdeatils.id right before deletion: \(matchDetails![0].id)")
        if let matchToDelete = realm.object(ofType: RMatchModel.self, forPrimaryKey: matchDetails![0].id) {
                try! realm.write {
                    realm.delete(matchToDelete)
                }
            
        }
        print("but we never get here")
        let matchCopy = db.collection("users").document(matchUserID).collection("matchStatuses").document(firebaseID)

        do {
           try await matchCopy.delete()
        } catch {
            print(error)
        }
        
        let chatRef = db.collection("chats").document(userChatID)
 
        do {
            try await chatRef.delete()
        } catch {
            print("error deleting chat: \(error)")
        }
        
        // what if they still chat to you after you've blocked them? would it still crash if we don't bother deleting chats?
        // and if not, why is it that when you delete a match, and they still try and chat, it doesn't crash? or does it?
        
        let realmChats = realm.objects(RChatDoc.self)
        print(realmChats.count)
        for chat in realmChats {
            print("deleting one: \(chat.chatID)")
            if chat.chatID == userChatID {
                try! realm.write {
                    realm.delete(chat)
                }
            }
        }
        }
    
    @objc func keyboardWillShow(_ notification: Notification) {
            
            if let userInfo = notification.userInfo, let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                
                chatFieldOriginalY = chatTextField.frame.origin.y
                let keyboardHeight = keyboardFrame.height
                let screenHeight = UIScreen.main.bounds.height
                
                let chatTextFieldY = screenHeight - keyboardHeight - chatTextField.frame.height - 5
                
                self.chatTextField.frame.origin.y = chatTextFieldY
                
                if sortedCurrentMessages.count > 8 {
                    
                    tableViewOriginalY = chatTableView.frame.origin.y
                    let distanceToMove = chatFieldOriginalY - chatTextField.frame.origin.y
                    self.chatTableView.frame.origin.y -= distanceToMove
                    scrollToBottom()
                }
            }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {

            chatTextField.frame.origin.y = chatFieldOriginalY
        if sortedCurrentMessages.count > 8 {
            chatTableView.frame.origin.y = tableViewOriginalY
        }
    }
    
    
    @IBAction func sendPressed(_ sender: UIButton) {
        
        if chatTextField.text != "" {
            
            if let safeMessage = chatTextField.text {
                
                Task.init {
                    
                    await saveChatToFirestore(safeMessage)
                }
                
            }
            chatTextField.text = ""
        }
    }
    
    func loadMatchDetails(_ matchID: String) async {
        
        if let currentUser = Auth.auth().currentUser {
            firebaseID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
        
        guard let realm = RealmManager.getRealm() else {return}

        try! realm.write {
            
            self.matchDetails = realm.objects(RMatchModel.self).filter("id == %@", matchID)
        }
    }
    
    func loadChatMessages() async {
        
        self.currentMessages = []
        self.sortedCurrentMessages = []
        
        guard let realm = RealmManager.getRealm() else {return}
        
        try! realm.write {
            
            let chats = realm.objects(RChatDoc.self).filter("chatID == %@", matchDetails![0].chatID)
            for chat in chats {
                self.currentMessages.append(chat)
            }
           
        }
        sortedCurrentMessages = currentMessages.sorted { $0.timeStamp! < $1.timeStamp! }
       
            chatTableView.reloadData()
        scrollToBottom()
                
            }

    
    func saveChatToFirestore(_ message: String) async {
        
        let newMessage = RChatDoc()
        newMessage.timeStamp = Date()
        newMessage.userID = firebaseID
        newMessage.message = message
        newMessage.chatID = matchDetails![0].chatID
        
        currentMessages.append(newMessage)
        sortedCurrentMessages = currentMessages.sorted { $0.timeStamp! < $1.timeStamp! }
        
        chatTableView.reloadData()
        scrollToBottom()
        
        do {
            
            let docRef = try await db.collection("chats").document(matchDetails![0].chatID).collection("messages").addDocument(data:
                                                                                                                [
                                                                                                                    "message" : message,
                                                                                                                    "ID" : firebaseID,
                                                                                                                    "timeStamp" : Date()
                                                                                                                ]
            )
            
            guard let realm = RealmManager.getRealm() else {return}
      
            try! realm.write {
                newMessage.id = docRef.documentID
                realm.add(newMessage)
            }
            
        } catch {
                print(error)
            }
    }

    
    func scrollToBottom() {
        
        if sortedCurrentMessages.count > 0 {
            
            let indexPath = IndexPath(row: sortedCurrentMessages.count - 1, section: 0)
            chatTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    

}

extension ChatViewController: UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if sortedCurrentMessages.count < 1 {
            return 1
        } else {
            
            return sortedCurrentMessages.count
        }
        
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = chatTableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath)
        
        
        if sortedCurrentMessages.count < 1 {
           
            cell.textLabel?.text = "Don't be shy! Send a message"
            
            return cell
        } else {
            
            cell.textLabel?.text = sortedCurrentMessages[indexPath.row].message
            cell.frame.size = CGSize(width: chatTableView.frame.width / 2, height: cell.frame.height)
            cell.layer.cornerRadius = 10
            cell.layer.masksToBounds = true
            
            if sortedCurrentMessages[indexPath.row].userID == firebaseID {
                
                cell.textLabel?.textAlignment = .right
                cell.backgroundColor = UIColor(red: 205/255, green: 243/255, blue: 245/255, alpha: 1.0)
            } else {
                
                cell.textLabel?.textAlignment = .left
                cell.backgroundColor = UIColor(red: 182/255, green: 250/255, blue: 187/255, alpha: 1.0)
            }
            
            return cell
        }
        
    }
}

extension ChatViewController: UITableViewDelegate {
    
    
}


extension ChatViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    
        chatTextField.endEditing(true)

        return true
        
    }

    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        
        chatTextField.resignFirstResponder()
        chatTextField.endEditing(true)
    }
    
}
