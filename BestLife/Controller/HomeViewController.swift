//
//  ViewController.swift
//  BestLife
//
//  Created by Jake Gordon on 05/12/2022.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class HomeViewController: UIViewController {

    @IBOutlet weak var helloUser: UILabel!
    var firebaseID: String?
    @IBOutlet weak var profilePicture: UIImageView!
    
    private let db = Firestore.firestore()
    var profileArray: [ProfileModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        let userID = IDgenerator()
        
        loadProfile()
    
        
        saveID(userID: userID)
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
    
    
    func loadProfile() {
        
        
        if let currentUser = Auth.auth().currentUser {
            firebaseID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
        
        let currentCollection = db.collection("users").document(firebaseID!).collection("profile")
        let query = currentCollection.whereField("userID", isEqualTo: firebaseID)
        
        query.getDocuments { querySnapshot, error in
            
            self.profileArray = []
            
            if let e = error {
                print("There was an issue retrieving data from Firestore: \(e)")
            } else {
                
                if let snapshotDocuments = querySnapshot?.documents {
                    
                    for doc in snapshotDocuments {
                        
                        let data = doc.data()
                        if let age = data["age"] as? String, let gender = data["gender"] as? String, let name = data["name"] as? String, let picture = data["picture"] as? String, let userID = data["userID"] as? String {
                            let profile = ProfileModel(age: age, gender: gender, name: name, picture: picture, userID: userID)
                            self.profileArray.append(profile)
    
                        
                            DispatchQueue.main.async {
                                
                                self.helloUser.text = "Hi \(profile.name)!"
                                
                                if let url = URL(string: profile.picture) {
                                    
                                    do {
                                        
                                        let data = try Data(contentsOf: url)
                                        let image = UIImage(data: data)
                                        self.profilePicture.image = image
                                    } catch {
                                        
                                        print("ERROR LOADING PROFILE IMAGE: \(error.localizedDescription)")
                                    }
                                }
                            }
                            
                        }
                    }
                }
            }
        }
    }

    
    
    @IBAction func createDatePressed(_ sender: UIButton) {
    }
    

}

