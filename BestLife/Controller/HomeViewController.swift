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

    override func viewDidLoad() {
        super.viewDidLoad()

        loadAllLocalData()
        loadProfile()
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
    
    func loadAllLocalData() {
        
        if let currentUser = Auth.auth().currentUser {
            firebaseID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
        
        // Grab user profile and write to Realm (displaying also)
        
        // Grab user's matches and write to Realm
        
        // Grab user's expiring requests and write to Realm
        
        // Grab user's chat messages and write to Realm
        
        
    }
    
    
    func loadProfile() {
        
        guard let realm = RealmManager.getRealm() else {return}
        
        
        if let currentUser = Auth.auth().currentUser {
            firebaseID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
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
        
        
//
//        let currentCollection = db.collection("users").document(firebaseID!).collection("profile")
//        let query = currentCollection.whereField("userID", isEqualTo: firebaseID)
//
//        query.getDocuments { querySnapshot, error in
//
//            self.profileArray = []
//
//            if let e = error {
//                print("There was an issue retrieving data from Firestore: \(e)")
//            } else {
//
//                if let snapshotDocuments = querySnapshot?.documents {
//
//                    for doc in snapshotDocuments {
//
//                        let data = doc.data()
//                        if let age = data["age"] as? Int, let gender = data["gender"] as? String, let name = data["name"] as? String, let picture = data["picture"] as? String, let userID = data["userID"] as? String {
//                            let profile = ProfileModel(age: age, gender: gender, name: name, picture: picture, userID: userID)
//                            self.profileArray.append(profile)
//
//
//                            DispatchQueue.main.async {
//
//                                self.helloUser.text = "Hi \(profile.name)!"
//
//                                if let url = URL(string: profile.picture) {
//
//                                    do {
//
//                                        self.profilePicture.kf.setImage(with: url)
//
                                        
//                                        let data = try Data(contentsOf: url)
//                                        let image = UIImage(data: data)
//                                        self.profilePicture.image = image
//                                    } catch {
//
//                                        print("ERROR LOADING PROFILE IMAGE: \(error.localizedDescription)")
//                                    }
//                                }
//                            }
//
//                        }
//                    }
//                }
//            }
//        }
    }

    
    
    @IBAction func createDatePressed(_ sender: UIButton) {
    }
    

}

