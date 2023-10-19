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
import CoreLocation


class AvailableDatesViewController: UIViewController {
    
    @IBOutlet weak var matchesButton: UIButton!
    @IBOutlet weak var availableDatesTable: UITableView!
    @IBOutlet weak var nooneAvailableMessage: UILabel!
    
    let db = Firestore.firestore()
    var statusArray: [DatePlanModel] = []
    var userProfileArray: [ProfileModel] = []
    var profilesArray: [ProfileModel] = []
    var dataLoadedArray: [Bool] = []
    var expiringMatchesArray: [RExpiringMatch] = []
    var ownName = "Jake"
    var dateActivity = "none"
    var dateTime = "none"
    var firebaseID = ""
    var notificationCount = 0
    var ownMatchStatus = MatchModel()
    var location = CLLocation()
    var passedMatchProfile = ProfileModel()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        for subview in matchesButton.subviews {
            
            subview.removeFromSuperview()
        }
        
        Task.init {
           
            do {
               notificationCount = await loadNotifications()

                
                let badgeSize: CGFloat = 17
                let badgeTag = 9830384
                
                let badgeLabel = UILabel(frame: CGRect(x: 0, y: 0, width: badgeSize, height: badgeSize))
                badgeLabel.translatesAutoresizingMaskIntoConstraints = false
                badgeLabel.tag = badgeTag
                badgeLabel.layer.cornerRadius = badgeLabel.bounds.size.height / 2
                badgeLabel.textAlignment = .center
                badgeLabel.layer.masksToBounds = true
                badgeLabel.backgroundColor = .red
                badgeLabel.textColor = .white
                badgeLabel.font = UIFont.boldSystemFont(ofSize: 10)
                
                
                if notificationCount <= 10 {
                    badgeLabel.text = String(notificationCount)
                } else {
                    badgeLabel.text = "10+"
                }
                
                badgeLabel.layer.zPosition = 1
                
                if notificationCount != 0 {
                    
                    matchesButton.addSubview(badgeLabel)
                    matchesButton.bringSubviewToFront(badgeLabel)
                    
                    badgeLabel.topAnchor.constraint(equalTo: matchesButton.topAnchor, constant: 4).isActive = true
                    badgeLabel.leftAnchor.constraint(equalTo: matchesButton.leftAnchor, constant: 10).isActive = true
                    badgeLabel.widthAnchor.constraint(equalToConstant: badgeSize).isActive = true
                    badgeLabel.heightAnchor.constraint(equalToConstant: badgeSize).isActive = true
                }
            } catch {
                print(error)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        nooneAvailableMessage.isHidden = true
        loadUserProfile()
        
        dataLoading()

        availableDatesTable.delegate = self
        availableDatesTable.dataSource = self
        availableDatesTable.rowHeight = 160.0
        
        availableDatesTable.register(UINib(nibName: "DatePlanCell", bundle: nil), forCellReuseIdentifier: "datePlanCell")
        
        if let currentUser = Auth.auth().currentUser {
            firebaseID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
        
        db.collection("users").document(firebaseID).collection("matchNotifications").addSnapshotListener { [self] snapshot, error in
            
            guard let snapshot = snapshot else {
                print("error fetching snapshot: \(error)")
                return
            }
            
            for change in snapshot.documentChanges {
                
                if change.type == .added {
                    
                    Task.init {
                       
                        do {
                            notificationCount = try await self.loadNotifications()

                            
                            let badgeSize: CGFloat = 17
                            let badgeTag = 9830384
                            
                            let badgeLabel = UILabel(frame: CGRect(x: 0, y: 0, width: badgeSize, height: badgeSize))
                            badgeLabel.translatesAutoresizingMaskIntoConstraints = false
                            badgeLabel.tag = badgeTag
                            badgeLabel.layer.cornerRadius = badgeLabel.bounds.size.height / 2
                            badgeLabel.textAlignment = .center
                            badgeLabel.layer.masksToBounds = true
                            badgeLabel.backgroundColor = .red
                            badgeLabel.textColor = .white
                            badgeLabel.font = UIFont.boldSystemFont(ofSize: 10)

                            
                            if notificationCount <= 10 {
                                badgeLabel.text = String(notificationCount)
                            } else {
                                badgeLabel.text = "10+"
                            }
                            
                            badgeLabel.layer.zPosition = 1
                            
                            if notificationCount != 0 {
                                
                                matchesButton.subviews.forEach { $0.removeFromSuperview() }
                                matchesButton.addSubview(badgeLabel)
                                matchesButton.bringSubviewToFront(badgeLabel)
                                
                                badgeLabel.topAnchor.constraint(equalTo: matchesButton.topAnchor, constant: 4).isActive = true
                                badgeLabel.leftAnchor.constraint(equalTo: matchesButton.leftAnchor, constant: 10).isActive = true
                                badgeLabel.widthAnchor.constraint(equalToConstant: badgeSize).isActive = true
                                badgeLabel.heightAnchor.constraint(equalToConstant: badgeSize).isActive = true
                            }
                        } catch {
                            print(error)
                        }
                        
                    }
                    
                }
            }
            
        }
         
    }
    

    @IBAction func matchesPressed(_ sender: UIButton) {
        
        performSegue(withIdentifier: "availableMatchesSeg", sender: self)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "availableMatchesSeg" {
            
            let destinationVC = segue.destination as! MatchesViewController
            
            ownMatchStatus.name = self.userProfileArray[0].name
            ownMatchStatus.imageURL = self.userProfileArray[0].picture
            ownMatchStatus.dateActivity = dateActivity
            ownMatchStatus.dateTime = dateTime
            ownMatchStatus.ID = firebaseID
            ownMatchStatus.age = self.userProfileArray[0].age
            ownMatchStatus.gender = self.userProfileArray[0].gender
            ownMatchStatus.accepted = false
            ownMatchStatus.fcmToken = UserDefaults.standard.object(forKey: "fcmToken") as! String

            destinationVC.ownMatch = ownMatchStatus
        }
        
        if segue.identifier == "availableMatchProfileSeg" {
            
            let destinationVC = segue.destination as! MatchProfileViewController
            
            destinationVC.matchProfile = self.passedMatchProfile
        }
    }
    
    
    func loadNotifications() async -> Int {
        
        var numberOfMatchRequests = 0
        
        if let currentUser = Auth.auth().currentUser {
            firebaseID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
            
            let currentCollection = db.collection("users").document(firebaseID).collection("matchNotifications")

            do {
                let querySnapshot = try await currentCollection.getDocuments()
                
                for doc in querySnapshot.documents {
                     
                    numberOfMatchRequests += 1
                    }
            } catch {
                print(error)
            }
        
        return numberOfMatchRequests
    }
    
    func dataLoading() {
        
        Task.init {
            do {
                try await loadExpiringMatches()
                expiringMatchesArray = try await filterExpiringMatches(matches: expiringMatchesArray)
                let statuses = try await loadStatuses()
                try await loadProfiles(statuses: statuses)
                self.dataLoadedArray.append(true)
                self.availableDatesTable.reloadData()
            } catch {
                print(error)
            }
            
        }
        
    }
    
    
    func loadStatuses() async -> [DatePlanModel] {
        
        var returnArray: [DatePlanModel] = []
        
        
        if let currentUser = Auth.auth().currentUser {
            firebaseID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
        
        let currentCollection = db.collection("statuses")
        let query = currentCollection.whereField("userID", isNotEqualTo: firebaseID)
        
        do {
            
            let querySnapshot = try await query.getDocuments()
            self.statusArray = []
                    
            for doc in querySnapshot.documents {
                        
                        let data = doc.data()
                        if let dateActivity = data["activity"] as? String, let dateTime = data["time"] as? String, let dateID = data["userID"] as? String, let docID = doc.documentID as? String, let fcmToken = data["fcmToken"] as? String, let latitude = data["latitude"] as? Double, let longitude = data["longitude"] as? Double {
                            let newStatus = DatePlanModel(dateActivity: dateActivity, dateTime: dateTime, daterID: dateID, firebaseDocID: docID, fcmToken: fcmToken, latitude: latitude, longitude: longitude)
                            self.statusArray.append(newStatus)
                            returnArray.append(newStatus)
                            
                            
                            self.statusArray = filterMatchLocations()
                            returnArray = self.statusArray
                            
                            
                            var expiredIDs: [String] = []
                 
                            for id in expiringMatchesArray {
                                
                                expiredIDs.append(id.userID)
                            }
                            
                            
                            for (index, status) in statusArray.enumerated() {
                             
                                if expiredIDs.contains(status.daterID) {
                                    statusArray.remove(at: index)
                                    returnArray.remove(at: index)
                                }
                                    
                            }
                            
                            DispatchQueue.main.async {
                                self.availableDatesTable.reloadData()
                            }
                        }
                        }
                    
        } catch {
            print(error)
        }
            
        return returnArray
    }
    
    func loadUserProfile() {
        
        if let currentUser = Auth.auth().currentUser {
            firebaseID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
        
        guard let realm = RealmManager.getRealm() else {return}
        self.userProfileArray = []
        
        if let realmProfile = realm.objects(RProfile.self).filter("userID == %@", firebaseID).first {
            
            let imageString = realmProfile.picture?.base64EncodedString()
            
            let profile = ProfileModel(age: realmProfile.age, gender: realmProfile.gender, name: realmProfile.name, picture: imageString ?? "none", userID: realmProfile.userID)
                                        self.userProfileArray.append(profile)
                                        self.dataLoadedArray.append(true)
            
                                        DispatchQueue.main.async {
            
                                            self.availableDatesTable.reloadData()
                                        }
        }
    }
    
    func loadProfiles(statuses: [DatePlanModel]) async {

        profilesArray = []
        
        if let currentUser = Auth.auth().currentUser {
            firebaseID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
        
        for status in statuses {
            
            let currentCollection = db.collection("users").document(status.daterID).collection("profile")
            let query = currentCollection.whereField("userID", isEqualTo: status.daterID)
           
            do {
                
                let querySnapshot = try await query.getDocuments()
               
                    
                for doc in querySnapshot.documents {

                        let data = doc.data()
                        if let age = data["age"] as? Int, let gender = data["gender"] as? String, let name = data["name"] as? String, let picture = data["picture"] as? String, let userID = data["userID"] as? String {
                            let profile = ProfileModel(age: age, gender: gender, name: name, picture: picture, userID: userID)
                            self.profilesArray.append(profile)
                         
                            var expiredIDs: [String] = []
                 
                            for id in expiringMatchesArray {
                                expiredIDs.append(id.userID)
                            }
                            
                            for (index, profile) in profilesArray.enumerated() {
                             
                                if expiredIDs.contains(profile.userID) {
                                    
                                    profilesArray.remove(at: index)
                                }
                                    
                            }
                            
                            
                            DispatchQueue.main.async {
                                
                                self.availableDatesTable.reloadData()
                            }
                            
                        }
                    }
            } catch {
                print(error)
            }
        }
 
    }
    
    func loadExpiringMatches() async {
        
        if let currentUser = Auth.auth().currentUser {
            firebaseID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
        
        guard let realm = RealmManager.getRealm() else {return}
        
        let expiringRequests = realm.objects(RExpiringMatch.self)
        for request in expiringRequests {
            self.expiringMatchesArray.append(request)
        }
    }
    
    func filterExpiringMatches(matches: [RExpiringMatch]) async -> [RExpiringMatch] {
        
        let newArray = matches
        var returnArray: [RExpiringMatch] = []
        let realm = RealmManager.getRealm()
        
        for expiringMatch in newArray {
            
            let currentTime = Date()
            let matchTimeStamp = expiringMatch.timeStamp!.addingTimeInterval(10800)

            
            if matchTimeStamp > currentTime {
                
                returnArray.append(expiringMatch)
            } else {
                if let safeRealm = realm {
                    if let expiringRequestToDelete = safeRealm.object(ofType: RExpiringMatch.self, forPrimaryKey: expiringMatch.id) {
                        try! safeRealm.write {
                            safeRealm.delete(expiringRequestToDelete)
                        }
                    }
                }
                
                let deleteMatchRef = db.collection("users").document(firebaseID).collection("expiringRequests").document(expiringMatch.userID)
                
                do {
                    try await deleteMatchRef.delete()
                } catch {
                    print("error deleting expired match: \(error)")
                }
            }
        }
        
        return returnArray
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
    
    func filterMatchLocations() -> [DatePlanModel] {
        
    var filteredArray: [DatePlanModel] = []
        var userLocation = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        
        for matchStatus in self.statusArray {
            
            var matchLocation = CLLocation(latitude: matchStatus.latitude, longitude: matchStatus.longitude)
           
            if matchLocation.distance(from: userLocation) <= UserDefaults.standard.value(forKey: "distancePreference") as! CLLocationDistance {
                filteredArray.append(matchStatus)
            }
        }
        return filteredArray
    }
    
    
}

//MARK: - TableView Data Source Methods

extension AvailableDatesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if dataLoadedArray.count != 2 {
            
            return 1
        } else {
            
            return (statusArray.count + 1)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var returnCell: UITableViewCell?
        
        if dataLoadedArray.count != 2 {
            
            let cell = availableDatesTable.dequeueReusableCell(withIdentifier: "dateCell", for: indexPath)
            cell.textLabel!.text = "Loading..."
            print("Loading... loaded")
            returnCell = cell
        } else {
 
            
            if indexPath.row == 0 {
                
                if statusArray.isEmpty {
                    nooneAvailableMessage.isHidden = false
                }
                
                let cell = availableDatesTable.dequeueReusableCell(withIdentifier: "dateCell", for: indexPath)
                
                cell.textLabel!.text = "I want to \(dateActivity) \(dateTime)"
                cell.textLabel!.textAlignment = .center
                cell.layer.backgroundColor = CGColor(red: 67.8, green: 84.7, blue: 90.2, alpha: 1.0)
                let lightBlue = UIColor(red: 240/255, green: 248/255, blue: 255/255, alpha: 1.0)
                cell.backgroundColor = lightBlue
                cell.isUserInteractionEnabled = false
                
                
                returnCell = cell
                
            } else {
                
                let cell = availableDatesTable.dequeueReusableCell(withIdentifier: "datePlanCell", for: indexPath) as! DatePlanCell
                                
                cell.delegate = self
                cell.indexPath = indexPath
                cell.acceptedButton.isHidden = true
                cell.rejectedButton.isHidden = true
           
                cell.datePlanLabel.text = "\(self.profilesArray[indexPath.row - 1].name) wants to \(self.statusArray[indexPath.row - 1].dateActivity) \(self.statusArray[indexPath.row - 1].dateTime)"
                cell.ageLabel.text = String(self.profilesArray[indexPath.row - 1].age)
                cell.genderLabel.text = self.profilesArray[indexPath.row - 1].gender
                
                DispatchQueue.main.async {
                    
                    if let url = URL(string: self.profilesArray[indexPath.row - 1].picture) {
                        
                        do {
                            
                            let data = try Data(contentsOf: url)
                            let image = UIImage(data: data)
                            cell.profilePicture.image = image
                        } catch {
                            
                            print("ERROR LOADING PROFILE IMAGE: \(error.localizedDescription)")
                        }
                    }
                }
                
                returnCell = cell
            }
        }
        return returnCell!
    }
}

//MARK: - TableView Delegate Methods

extension AvailableDatesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        if indexPath.row == 0 {
            
            return 44.0
        } else {
            
            return 176.0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let confirmMatchAlert = UIAlertController(title: "Great Stuff!", message: "Are you sure you want to connect with this person?", preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Yes!", style: .default) { [self] alertAction in
            
            Task.init {
                let alreadyMatched = await checkIfAlreadyMatched(indexPath: indexPath)
                
                if alreadyMatched {
                    
                    let alreadyMatchedAlert = UIAlertController(title: "Uh oh", message: "Looks like the two of you are already connected. Try sending them a message instead!", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Okay", style: .default)
                    alreadyMatchedAlert.addAction(okAction)
                    present(alreadyMatchedAlert, animated: true)
                    
                } else {
                    matchWithUser(indexPath: indexPath)
                }
            }
        }
        
        let nopeAction = UIAlertAction(title: "Oops nope", style: .default)
        confirmMatchAlert.addAction(okayAction)
        confirmMatchAlert.addAction(nopeAction)
        present(confirmMatchAlert, animated: true)
    }
    
    func checkIfAlreadyMatched(indexPath: IndexPath) async -> Bool {

        guard let realm = RealmManager.getRealm() else {return false}
        
        let existingMatches = realm.objects(RMatchModel.self)
        for match in existingMatches {
            if match.userID == statusArray[indexPath.row - 1].daterID {
                return true
            }
        }
        return false
    }
    
    func matchWithUser(indexPath: IndexPath) {
        
        guard let realm = RealmManager.getRealm() else {return}

        db.collection("users").document(firebaseID).collection("expiringRequests").document(statusArray[indexPath.row - 1].daterID).setData([
            "timeStamp": Date(),
            "userID": statusArray[indexPath.row - 1].daterID
        ]) { [self] err in
            
            if let err = err {
                print("error writing doc: \(err)")
            } else {
                
                let id = db.collection("users").document(firebaseID).collection("expiringRequests").document(statusArray[indexPath.row - 1].daterID).documentID
                
                try! realm.write {
                    var realmExpiringMatch = RExpiringMatch()
                    realmExpiringMatch.id = id
                    realmExpiringMatch.userID = firebaseID
                    realmExpiringMatch.timeStamp = Date()
                    realm.add(realmExpiringMatch, update: .all)
                }
                print("doc written successfully.")
            }
        }
        
        db.collection("users").document(statusArray[indexPath.row - 1].daterID).collection("matchStatuses").document(firebaseID).setData([
            "name" : self.userProfileArray[0].name,
            "imageURL" : self.userProfileArray[0].picture,
                "activity" : dateActivity,
                "time" : dateTime,
                "ID" : firebaseID,
                "age" : self.userProfileArray[0].age,
                "gender" : self.userProfileArray[0].gender,
            "accepted" : false,
            "fcmToken" : UserDefaults.standard.object(forKey: "fcmToken"),
            "realmID" : UUID().uuidString
        ]) { err in
            if let err = err {
                print("error writing doc: \(err)")
            } else {
                print("doc written successfully.")
            }
        }
        
        var daterID = statusArray[indexPath.row - 1].daterID
        
        Task.init {
            await addNotification(daterID: daterID, firebaseID: firebaseID)
        }

        let docRef1 = db.collection("statuses").document(statusArray[indexPath.row - 1].firebaseDocID)
        
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
            
            let myFunctions = Functions.functions()
            let passedID = document.data()?["fcmToken"] as? String
            
            let data: [String: Any] = [
                "tapperID": field,
                "tappedID": passedID!
            ]

           
            myFunctions.httpsCallable("notifyUser").call(data) { result, error in
                
                    if let error = error {
                        print("Error calling function: \(error.localizedDescription)")
                    } else if let result = result {
                        print("Function result: \(result.data)")
                    }
                }
            
            
        
        }
        
        self.statusArray.remove(at: indexPath.row - 1)
        self.profilesArray.remove(at: indexPath.row - 1)
        self.availableDatesTable.reloadData()
    }
}


extension AvailableDatesViewController: CustomTableViewCellDelegate {
    
    
    func customTableViewCellDidTapButton(_ cell: DatePlanCell, indexPath: IndexPath, buttonName: String) async {

        if buttonName == "viewProfileButton" {
            
            passedMatchProfile.age = profilesArray[indexPath.row - 1].age
            passedMatchProfile.name = profilesArray[indexPath.row - 1].name
            passedMatchProfile.gender = profilesArray[indexPath.row - 1].gender
            passedMatchProfile.picture = profilesArray[indexPath.row - 1].picture
            
            performSegue(withIdentifier: "availableMatchProfileSeg", sender: self)
        }
    }
    
}
