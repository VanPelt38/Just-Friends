//
//  MessagesViewController.swift
//  BestLife
//
//  Created by Jake Gordon on 28/12/2023.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import Firebase
import FirebaseFirestore
import FirebaseFunctions
import RealmSwift
import Kingfisher

class MessageViewController: MessagesViewController {
    
    var firebaseID = ""
    var matchID = ""
    private let db = Firestore.firestore()
    var matchDetails: Results<RMatchModel>?
    var currentMessages: [RChatDoc] = []
    var sortedCurrentMessages: [RChatDoc] = []
    var finalMessages: [Message] = []
    var sender = Sender(name: "none", id: "100")
    var ownMatch = MatchModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let currentTime = Date()
        
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "arrow25"), style: .plain, target: self, action: #selector(popVC))
        
        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.register(CustomCommentCell.self)
        messagesCollectionView.reloadData()
        
        currentMessages = []
        sortedCurrentMessages = []
        
        Task.init {
            
            await loadMatchDetails(matchID)
            await loadChatMessages()
            
            db.collection("chats").document(matchDetails![0].chatID).collection("messages").addSnapshotListener { [self] snapshot, error in
                
                guard let snapshot = snapshot else {
                    print("error fetching snapshot: \(error)")
                    return
                }
                
                if let error = error {
                    print("listener error: \(error.localizedDescription)")
                }
                
                for change in snapshot.documentChanges {
                    
                    if change.type == .added {
                        
                        let documentData = change.document.data()
                        
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
                                    
                                    let newMess = Message(id: "1", date: messageTime, message: message, sender: Sender(name: matchDetails![0].name, id: userID))
                                    finalMessages.append(newMess)
                                }
                              
                                   messagesCollectionView.reloadData()
                                messagesCollectionView.scrollToLastItem()
                            }
                        }
                        
                    }
                }
                
            }

        }
    }
    
    @objc func popVC() {
        navigationController?.popViewController(animated: true)
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
            self.navigationItem.title = matchDetails![0].name
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
        
        for message in sortedCurrentMessages {
            let newMessage = Message(id: "1", date: message.timeStamp!, message: message.message, sender: Sender(name: (message.userID == firebaseID) ? firebaseID : matchDetails![0].userID, id: (message.userID == firebaseID) ? self.sender.displayName : matchDetails![0].name))
            finalMessages.append(newMessage)
        }
       
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem()
                
            }
    
    func saveChatToFirestore(_ message: String) async {
        
        let newMessage = RChatDoc()
        newMessage.timeStamp = Date()
        newMessage.userID = firebaseID
        newMessage.message = message
        newMessage.chatID = matchDetails![0].chatID
        let newMess = Message(id: "1", date: Date(), message: message, sender: Sender(name: firebaseID, id: ownMatch.name))
        finalMessages.append(newMess)
        
             messagesCollectionView.reloadData()
          messagesCollectionView.scrollToLastItem()
        
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
                                let reportSentAlert = UIAlertController(title: "Report Sent Successfully", message: "Thanks for letting us know - our team will investigate your concern thoroughly and take any appropriate actions.", preferredStyle: .alert)
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
            
            
            let areYouSureAlert = UIAlertController(title: "Are you sure you'd like to block this user?", message: "They will no longer be able to contact you, and you will be hidden from each other's 'Available' feeds.", preferredStyle: .alert)
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
                    
                    let blockSuccessfulAlert = UIAlertController(title: "Success", message: "This user will no longer be able to see or interact with you.", preferredStyle: .alert)
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
      
        if let matchToDelete = realm.object(ofType: RMatchModel.self, forPrimaryKey: matchDetails![0].id) {
                try! realm.write {
                    realm.delete(matchToDelete)
                }
            
        }
     
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
        
        let realmChats = realm.objects(RChatDoc.self)
        print(realmChats.count)
        for chat in realmChats {
            if chat.chatID == userChatID {
                try! realm.write {
                    realm.delete(chat)
                }
            }
        }
        }
    
}

extension MessageViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate, InputBarAccessoryViewDelegate {
    
    var currentSender: MessageKit.SenderType {
        return sender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return finalMessages[indexPath.section]
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        if let matchImage = URL(string: matchDetails![0].imageURL), let myImage = URL(string: ownMatch.imageURL) {
            if isFromCurrentSender(message: message) {
                avatarView.kf.setImage(with: myImage)
            } else {
                avatarView.kf.setImage(with: matchImage)
            }
        }
        
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        if isFromCurrentSender(message: message) {
            return UIColor(red: 135/255, green: 206/255, blue: 235/255, alpha: 1.0)
        } else {
            return UIColor(red: 218/255, green: 247/255, blue: 166/255, alpha: 1.0)
        }
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return finalMessages.count
    }
    
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
            
                Task.init {

                    await saveChatToFirestore(text)
                    inputBar.inputTextView.text = ""
                }
    }
}
