//
//  AvailableDatesViewController.swift
//  BestLife
//
//  Created by Jake Gordon on 15/12/2022.
//

import UIKit
import Firebase
import FirebaseFunctions
import FirebaseAuth


class AvailableDatesViewController: UIViewController {
    

    
    @IBOutlet weak var matchesButton: UIBarButtonItem!
    
    @IBOutlet weak var availableDatesTable: UITableView!
    
    
    
    let db = Firestore.firestore()
    
    var statusArray: [DatePlanModel] = []
    
    var ownName = "Jake"
    var dateActivity = "none"
    var dateTime = "none"
    var firebaseID = ""
    

    override func viewDidLoad() {
        super.viewDidLoad()
        

        availableDatesTable.delegate = self
        availableDatesTable.dataSource = self
        availableDatesTable.rowHeight = 160.0
        
        loadStatuses()
    }
    
    @IBAction func matchesPressed(_ sender: UIBarButtonItem) {
        
        
    }
    
    
    func loadStatuses() {
        
//        let uniqueID = UserDefaults.standard.object(forKey: "uniqueID")
        
        
        if let currentUser = Auth.auth().currentUser {
            firebaseID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
        
        let currentCollection = db.collection("statuses")
        let query = currentCollection.whereField("userID", isNotEqualTo: firebaseID)
        
        query.getDocuments { querySnapshot, error in
            
            self.statusArray = []
            
            if let e = error {
                print("There was an issue retrieving data from Firestore: \(e)")
            } else {
                
                if let snapshotDocuments = querySnapshot?.documents {
                    
                    for doc in snapshotDocuments {
                        
                        let data = doc.data()
                        if let dateActivity = data["activity"] as? String, let dateTime = data["time"] as? String, let dateID = data["userID"] as? String, let docID = doc.documentID as? String, let fcmToken = data["fcmToken"] as? String {
                            let newStatus = DatePlanModel(dateActivity: dateActivity, dateTime: dateTime, daterID: dateID, firebaseDocID: docID, fcmToken: fcmToken)
                            self.statusArray.append(newStatus)
                            print(self.statusArray.count)
                        
                            DispatchQueue.main.async {
                                
                                self.availableDatesTable.reloadData()
                            }
                            
                        }
                    }
                }
            }
        }
    }
    
}

//MARK: - TableView Data Source Methods

extension AvailableDatesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return (statusArray.count + 1)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
       
        
            let cell = availableDatesTable.dequeueReusableCell(withIdentifier: "dateCell", for: indexPath)

        if indexPath.row == 0 {
            
            cell.textLabel?.text = "I want to \(dateActivity) \(dateTime)"
        } else {
            
            cell.textLabel?.text = "I want to \(statusArray[(indexPath.row - 1)].dateActivity) \(statusArray[(indexPath.row - 1)].dateTime)"
        }
      
      
        return cell
    }
    
}

//MARK: - TableView Delegate Methods

extension AvailableDatesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.row == 0 {
            
            return 40.0
        } else {
            
            return 160.0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let confirmMatchAlert = UIAlertController(title: "Great Stuff!", message: "Are you sure you want to match with this person?", preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Yes!", style: .default) { [self] alertAction in
            
            let docRef1 = db.collection("statuses").document(statusArray[indexPath.row - 1].firebaseDocID)
            
            print(db.collection("statuses").document(statusArray[indexPath.row - 1].dateActivity))
            
            let tappedPersonID = statusArray[indexPath.row - 1].daterID
            let docRef = db.collection("statuses").document(statusArray[indexPath.row - 1].firebaseDocID)
            docRef.updateData(["suitorID" : firebaseID]) { err in
                if let err = err {
                    print("error updating field: \(err)")
                } else {
                    print("success")
                }
                
            }

            docRef1.addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                guard let field = document.data()?["suitorID"] as? String else {
                    print("Field does not exist")
                    return
                }
                print("Current field value: \(field)")
                
                let myFunctions = Functions.functions()
                let passedID = document.data()?["fcmToken"] as? String
                
                let data: [String: Any] = [
                    "tapperID": field,
                    "tappedID": passedID
                ]
                
                
               
                myFunctions.httpsCallable("notifyUser").call(data) { result, error in
                    
                        if let error = error {
                            print("Error calling function: \(error.localizedDescription)")
                        } else if let result = result {
                            print("Function result: \(result.data ?? "")")
                        }
                    }
                
                
            
            }
  

        }
        
        let nopeAction = UIAlertAction(title: "Oops nope", style: .default)
        confirmMatchAlert.addAction(okayAction)
        confirmMatchAlert.addAction(nopeAction)
        present(confirmMatchAlert, animated: true)
    }
}
