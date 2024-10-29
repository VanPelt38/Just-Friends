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
import Kingfisher


class AvailableDatesViewController: BaseViewController {
    
    @IBOutlet weak var matchesButton: UIButton!
    @IBOutlet weak var availableDatesTable: UITableView!
    @IBOutlet weak var nooneAvailableMessage: UILabel!
    
    let db = Firestore.firestore()
    var statusArray: [DatePlanModel] = []
    var userProfileArray: [ProfileModel] = []
    var profilesArray: [ProfileModel] = []
    var dataLoadedArray: [Bool] = []
    var expiringMatchesArray: [RExpiringMatch] = []
    var ownName = "none"
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
        nooneAvailableMessage.translatesAutoresizingMaskIntoConstraints = false
        let centerXConstraint = NSLayoutConstraint(item: nooneAvailableMessage,
                                                   attribute: .centerX,
                                                   relatedBy: .equal,
                                                   toItem: view,
                                                   attribute: .centerX,
                                                   multiplier: 1.0,
                                                   constant: 0.0)
        let centerYConstraint = NSLayoutConstraint(item: nooneAvailableMessage,
                                                   attribute: .centerY,
                                                   relatedBy: .equal,
                                                   toItem: view,
                                                   attribute: .centerY,
                                                   multiplier: 1.0,
                                                   constant: 0.0)
        let widthConstraint = NSLayoutConstraint(item: nooneAvailableMessage,
                                                 attribute: .width,
                                                 relatedBy: .equal,
                                                 toItem: nil,
                                                 attribute: .notAnAttribute,
                                                 multiplier: 1.0,
                                                 constant: 330.0)  // Adjust as needed

        let heightConstraint = NSLayoutConstraint(item: nooneAvailableMessage,
                                                  attribute: .height,
                                                  relatedBy: .equal,
                                                  toItem: nil,
                                                  attribute: .notAnAttribute,
                                                  multiplier: 1.0,
                                                  constant: 170.0)
        
        view.addConstraints([centerXConstraint, centerYConstraint, widthConstraint, heightConstraint])
        
        loadUserProfile()
        
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "arrow25"), style: .plain, target: self, action: #selector(popVC))
        
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
        self.showToast(message: "Your plan will be available for 12 hours")
    }
    
    @objc func popVC() {
        navigationController?.popViewController(animated: true)
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
            destinationVC.matchID = passedMatchProfile.userID
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
                self.showShareAlert()
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
                        if let dateActivity = data["activity"] as? String, let dateTime = data["time"] as? String, let dateID = data["userID"] as? String, let docID = doc.documentID as? String, let fcmToken = data["fcmToken"] as? String, let latitude = data["latitude"] as? Double, let longitude = data["longitude"] as? Double, let timeStamp = data["timeStamp"] as? Timestamp {

                            let newStatus = DatePlanModel(dateActivity: dateActivity, dateTime: dateTime, daterID: dateID, firebaseDocID: docID, fcmToken: fcmToken, latitude: latitude, longitude: longitude, timeStamp: timeStamp.dateValue())
                            self.statusArray.append(newStatus)
                            returnArray.append(newStatus)
                          
                            self.statusArray = filterMatchLocations()
                            self.statusArray = filterExpiredStatuses()
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
                            guard let realm = RealmManager.getRealm() else {return returnArray}
                            
                           let blockUsers = realm.objects(BlockedUser.self).filter("userID == %@", firebaseID)
                            
                            let blockedIDs = blockUsers.map { $0.blockID }
                            
                            for (index, status) in statusArray.enumerated() {
                                if blockedIDs.contains(status.daterID) {
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

            let profile = ProfileModel(age: realmProfile.age, gender: realmProfile.gender, name: realmProfile.name, picture: realmProfile.profilePicURL, userID: realmProfile.userID)
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
        
        let expiringRequests = realm.objects(RExpiringMatch.self).filter("ownUserID == %@", firebaseID)
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
                
                let deleteMatchRef = db.collection("users").document(firebaseID).collection("expiringRequests").document(expiringMatch.userID)
                do {
                    try await deleteMatchRef.delete()
                        
                                        if let safeRealm = realm {
                                            if let expiringRequestToDelete = safeRealm.object(ofType: RExpiringMatch.self, forPrimaryKey: expiringMatch.id) {
                                                try! safeRealm.write {
                                                    safeRealm.delete(expiringRequestToDelete)
                                                }
                                            }
                                        }
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
        let userLocation = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        
        for matchStatus in self.statusArray {
            
            let matchLocation = CLLocation(latitude: matchStatus.latitude, longitude: matchStatus.longitude)
           
            if matchLocation.distance(from: userLocation) <= UserDefaults.standard.value(forKey: "distancePreference") as! CLLocationDistance {
                filteredArray.append(matchStatus)
                var distance = (Int(matchLocation.distance(from: userLocation))) / 1000
                filteredArray[filteredArray.count - 1].distanceAway = distance >= 1 ? distance : 1
            }
        }
        return filteredArray
    }
    
    func filterExpiredStatuses() -> [DatePlanModel] {
        
    var filteredArray: [DatePlanModel] = []
        
        let currentTime = Date()
        
        for matchStatus in self.statusArray {
            
            let expiryTime = matchStatus.timeStamp?.addingTimeInterval(12 * 60 * 60)
            
            if currentTime <= expiryTime! {
                filteredArray.append(matchStatus)
            }
        }
        return filteredArray
    }
    
    func showShareAlert() {
        
        if timeHasElapsed() {
            
            let shareAlert = UIAlertController(title: "Share with friends!", message: "Spread the word about our app and start building a community.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Share", style: .default) { _ in
                self.shareApp()
            }
            let noAction = UIAlertAction(title: "Not right now", style: .default)
            shareAlert.addAction(okAction)
            shareAlert.addAction(noAction)
            self.present(shareAlert, animated: true)
        }
    }
    
    func timeHasElapsed() -> Bool {
        
        if let lastShareDate = UserDefaults.standard.object(forKey: "lastShareDate") as? Date {
            
            let timeInterval = Date().timeIntervalSince(lastShareDate)
            if timeInterval > TimeInterval(48 * 60 * 60) {
                UserDefaults.standard.set(Date(), forKey: "lastShareDate")
                return true
            } else {
                return false
            }
        } else {
            UserDefaults.standard.set(Date(), forKey: "lastShareDate")
            return true
        }
    }
    
    func shareApp() {
        
        let activityVC = UIActivityViewController(activityItems: ["Join me on Just Friends!", URL(string: "https://apps.apple.com/us/app/just-friends/id6462937691")], applicationActivities: nil)
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        present(activityVC, animated: true)
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
                cell.textLabel?.font = UIFont(name: "Gill Sans", size: 20)
                cell.textLabel!.textAlignment = .center
                cell.layer.backgroundColor = CGColor(red: 67.8, green: 84.7, blue: 90.2, alpha: 1.0)
                let lightBlue = UIColor(red: 240/255, green: 248/255, blue: 255/255, alpha: 1.0)
                cell.backgroundColor =  UIColor(red: 245/255, green: 195/255, blue: 194/255, alpha: 0.5)
                cell.isUserInteractionEnabled = false
                
                
                returnCell = cell
                
            } else {
                
                let cell = availableDatesTable.dequeueReusableCell(withIdentifier: "datePlanCell", for: indexPath) as! DatePlanCell
                                
                cell.delegate = self
                cell.indexPath = indexPath
                cell.acceptedButton.isHidden = true
                cell.rejectedButton.isHidden = true
                cell.distanceAwayLabel.text = "\(self.statusArray[indexPath.row - 1].distanceAway) km away"
                cell.profilePicture.layer.cornerRadius = cell.profilePicture.frame.width / 2
                cell.profilePicture.clipsToBounds = true
           
                cell.datePlanLabel.text = "\(self.profilesArray[indexPath.row - 1].name) wants to \(self.statusArray[indexPath.row - 1].dateActivity) \(self.statusArray[indexPath.row - 1].dateTime)"
                cell.ageLabel.text = String(self.profilesArray[indexPath.row - 1].age)
                cell.genderLabel.image = UIImage(named: "big male")
                if self.profilesArray[indexPath.row - 1].gender == "female" {
                    cell.genderLabel.image = UIImage(named: "big female")
                }
                
                DispatchQueue.main.async {
                    
                    if let url = URL(string: self.profilesArray[indexPath.row - 1].picture) {
                        
                        cell.profilePicture.kf.setImage(with: url)
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
            
            return 150.0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let confirmMatchAlert = UIAlertController(title: "Great Stuff", message: "Are you sure you want to connect with this person?", preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Yes", style: .default) { [self] alertAction in
            
            Task.init {
                let alreadyMatched = await checkIfAlreadyMatched(indexPath: indexPath)
                if alreadyMatched {
                    
                    let alreadyMatchedAlert = UIAlertController(title: "Uh-oh", message: "Looks like the two of you are already connected. Try sending them a message instead.", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Okay", style: .default)
                    alreadyMatchedAlert.addAction(okAction)
                    present(alreadyMatchedAlert, animated: true)
                    
                } else {
                    matchWithUser(indexPath: indexPath)
                }
            }
        }
        
        let nopeAction = UIAlertAction(title: "No", style: .default)
        confirmMatchAlert.addAction(okayAction)
        confirmMatchAlert.addAction(nopeAction)
        present(confirmMatchAlert, animated: true)
    }
    
    func checkIfAlreadyMatched(indexPath: IndexPath) async -> Bool {

        guard let realm = RealmManager.getRealm() else {return false}
        
        let existingMatches = realm.objects(RMatchModel.self).filter("ownUserID == %@", firebaseID)
        for match in existingMatches {
            if match.userID == statusArray[indexPath.row - 1].daterID {
                return true
            }
        }
        return false
    }
    
    func matchWithUser(indexPath: IndexPath) {
        
        
        guard let realm = RealmManager.getRealm() else {return}
        
        let daterID = statusArray[indexPath.row - 1].daterID
        let dateName = userProfileArray[0].name
        let dateFirebaseDocID = statusArray[indexPath.row - 1].firebaseDocID
        
        let docRef1 = db.collection("statuses").document(dateFirebaseDocID)
        docRef1.getDocument { [self] querySnap, error in
            
            if let gotDoc = querySnap, gotDoc.exists {
                
                db.collection("users").document(firebaseID).collection("expiringRequests").document(daterID).setData([
                    "timeStamp": Date(),
                    "userID": daterID,
                    "ownUserID": firebaseID
                ]) { [self] err in
                    
                    if let err = err {
                        print("error writing doc: \(err)")
                    } else {

                        let id = db.collection("users").document(firebaseID).collection("expiringRequests").document(daterID).documentID
                        
                        try! realm.write {
                            let realmExpiringMatch = RExpiringMatch()
                            realmExpiringMatch.id = id
                            realmExpiringMatch.userID = daterID
                            realmExpiringMatch.timeStamp = Date()
                            realmExpiringMatch.ownUserID = firebaseID
                            realm.add(realmExpiringMatch, update: .all)
                        }
                    }
                }
                
                db.collection("users").document(daterID).collection("matchStatuses").document(firebaseID).setData([
                    "name" : self.userProfileArray[0].name,
                    "imageURL" : self.userProfileArray[0].picture,
                        "activity" : dateActivity,
                        "time" : dateTime,
                        "ID" : firebaseID,
                        "age" : self.userProfileArray[0].age,
                        "gender" : self.userProfileArray[0].gender,
                    "accepted" : false,
                    "fcmToken" : UserDefaults.standard.object(forKey: "fcmToken"),
                    "realmID" : UUID().uuidString,
                    "ownUserID" : daterID,
                    "chatID" : "none",
                    "distanceAway" : statusArray[indexPath.row - 1].distanceAway
                ]) { err in
                    if let err = err {
                        print("error writing doc: \(err)")
                    } else {
                        print("doc written successfully.")
                    }
                }
                
                Task.init {
                    await addNotification(daterID: daterID, firebaseID: firebaseID)
                }
                
                let tappedPersonID = daterID
                let docRef = db.collection("statuses").document(dateFirebaseDocID)
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
                        "tappedID": passedID!,
                        "tapperName": dateName
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
                self.showToast(message: "Your request has been sent!")
                
                
            } else if let e = error {
                print("error matching`: \(e)")
            } else {
                
                let userDoesNotExistAlert = UIAlertController(title: "Uh-oh", message: "Unfortunately this user is no longer available.", preferredStyle: .alert)
                let okayAction = UIAlertAction(title: "Okay", style: .default)
                userDoesNotExistAlert.addAction(okayAction)
                present(userDoesNotExistAlert, animated: true)
                
            }
        }
    }
}


extension AvailableDatesViewController: CustomTableViewCellDelegate {
    
    
    func customTableViewCellDidTapButton(_ cell: DatePlanCell, indexPath: IndexPath, buttonName: String) async {

        if buttonName == "viewProfileButton" {
            
            passedMatchProfile.age = profilesArray[indexPath.row - 1].age
            passedMatchProfile.name = profilesArray[indexPath.row - 1].name
            passedMatchProfile.gender = profilesArray[indexPath.row - 1].gender
            passedMatchProfile.picture = profilesArray[indexPath.row - 1].picture
            passedMatchProfile.userID = profilesArray[indexPath.row - 1].userID
            
            performSegue(withIdentifier: "availableMatchProfileSeg", sender: self)
        }
    }
    
}
