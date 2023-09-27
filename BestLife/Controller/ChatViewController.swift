//
//  ChatViewController.swift
//  BestLife
//
//  Created by Jake Gordon on 15/12/2022.
//

import UIKit
import Firebase
import FirebaseFirestore
import IQKeyboardManagerSwift

class ChatViewController: UIViewController {

    @IBOutlet weak var chatTableView: UITableView!
    
    @IBOutlet weak var chatTextField: UITextField!
    
    var firebaseID = ""
    var matchID = ""
    private let db = Firestore.firestore()
    var matchDetails = MatchModel()
    var currentMessages: [MessageModel] = []
    var sortedCurrentMessages: [MessageModel] = []
    var chatFieldOriginalY: CGFloat = 0.0
    var tableViewOriginalY: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let currentTime = Date()
        
        IQKeyboardManager.shared.disabledDistanceHandlingClasses.append(ChatViewController.self)
        

        currentMessages = []
        sortedCurrentMessages = []
        
        Task.init {
            await loadMatchDetails(matchID)
            await loadChatMessages()

            db.collection("chats").document(matchDetails.chatID).collection("messages").addSnapshotListener { [self] snapshot, error in
                
                guard let snapshot = snapshot else {
                    print("error fetching snapshot: \(error)")
                    return
                }
                
                for change in snapshot.documentChanges {
                    
                    if change.type == .added {
                        
                        let documentData = change.document.data()
                        
                        if let time = documentData["timeStamp"] as? Timestamp {
                            
                            let messageTime = time.dateValue()
                            
                            if messageTime > currentTime {
                                
                                
                                currentMessages = []
                                sortedCurrentMessages = []
                                
                                Task.init {
                                    try await loadChatMessages()
                                    
                                    chatTableView.reloadData()
                                    scrollToBottom()
                                }
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
        
        let currentCollection = db.collection("users").document(firebaseID).collection("matchStatuses")
        let query = currentCollection.whereField("ID", isEqualTo: matchID)
        
        do {
            let querySnapshot = try await query.getDocuments()
        

                    
                    for doc in querySnapshot.documents {
                        
                        let data = doc.data()
                        if let age = data["age"] as? Int, let gender = data["gender"] as? String, let name = data["name"] as? String, let picture = data["imageURL"] as? String, let userID = data["ID"] as? String, let accepted = data["accepted"] as? Bool, let activity = data["activity"] as? String, let time = data["time"] as? String, let chatID = data["chatID"] as? String, let fcmToken = data["fcmToken"] as? String {
                            
                            let newModel = MatchModel(name: name, age: age, gender: gender, imageURL: picture, dateActivity: activity, dateTime: time, ID: userID, accepted: accepted, fcmToken: fcmToken, chatID: chatID)
                            self.matchDetails = newModel
                        }
                    }
                
        } catch {
            print("there was error getting firestore stuff: \(error)")
        }
    }
    
    func loadChatMessages() async {

        self.currentMessages = []
        self.sortedCurrentMessages = []
            
            let currentCollection = db.collection("chats").document(matchDetails.chatID).collection("messages")
          
        do {
            let querySnapshot = try await currentCollection.getDocuments()
           
                    
                
                        
            for doc in querySnapshot.documents {
                            
                           
                            
                            let data = doc.data()
                            if let message = data["message"] as? String, let userID = data["ID"] as? String, let timeStamp = data["timeStamp"] as? Timestamp {
                                let time = timeStamp.dateValue()
                                
                                var newMessage = MessageModel(userID: userID, message: message, time: time)
                                
                                self.currentMessages.append(newMessage)
                                
                               
                                
                            }
                        }
        } catch {
            print("error loading: \(error)")
                }
            
            
            sortedCurrentMessages = currentMessages.sorted { $0.time! < $1.time! }
       
            chatTableView.reloadData()
        scrollToBottom()
                
            }

    
    func saveChatToFirestore(_ message: String) async {


        var newMessage = MessageModel(userID: firebaseID, message: message, time: Date())
        
        currentMessages.append(newMessage)
        sortedCurrentMessages = currentMessages.sorted { $0.time! < $1.time! }
        
        chatTableView.reloadData()
        scrollToBottom()
        
        do {
            
            try await db.collection("chats").document(matchDetails.chatID).collection("messages").addDocument(data:
                                                                                                                [
                                                                                                                    "message" : message,
                                                                                                                    "ID" : firebaseID,
                                                                                                                    "timeStamp" : Date()
                                                                                                                ]
            ) } catch {
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
            
            if sortedCurrentMessages[indexPath.row].userID == firebaseID {
                
                cell.textLabel?.textAlignment = .right
                cell.backgroundColor = .blue
            } else {
                
                cell.textLabel?.textAlignment = .left
                cell.backgroundColor = .green
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
