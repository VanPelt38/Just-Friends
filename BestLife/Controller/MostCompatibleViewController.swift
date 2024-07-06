//
//  MostCompatibleViewController.swift
//  BestLife
//
//  Created by Jake Gordon on 23/06/2024.
//

import UIKit
import Firebase
import FirebaseFunctions
import FirebaseAuth
import CoreLocation
import Kingfisher
import RealmSwift

class MostCompatibleViewController: UIViewController {
    
    
    @IBOutlet weak var mostCompatibleTable: UITableView!
    @IBOutlet weak var mostCompatibleLabel: UILabel!
    @IBOutlet weak var matchesButton: UIButton!
    @IBOutlet weak var calculateButton: UIButton!
    
    let db = Firestore.firestore()
    var profilesArray: [RCompatible] = []
//    var dataLoadedArray: [Bool] = []
    var expiringMatchesArray: [RExpiringMatch] = []
    var ownName = "none"
    var firebaseID = ""
    var notificationCount = 0
    var ownMatchStatus = MatchModel()
    var myLocation = CLLocation()
    var passedMatchProfile = ProfileModel()
    var myProfile = RProfile()
    let locationManager = CLLocationManager()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mostCompatibleLabel.isHidden = true
        mostCompatibleLabel.translatesAutoresizingMaskIntoConstraints = false
        calculateButton.layer.cornerRadius = calculateButton.frame.height / 2
        calculateButton.backgroundColor = UIColor(red: 255/255, green: 204/255, blue: 204/255, alpha: 1.0)
        let centerXConstraint = NSLayoutConstraint(item: mostCompatibleLabel,
                                                   attribute: .centerX,
                                                   relatedBy: .equal,
                                                   toItem: view,
                                                   attribute: .centerX,
                                                   multiplier: 1.0,
                                                   constant: 0.0)
        let centerYConstraint = NSLayoutConstraint(item: mostCompatibleLabel,
                                                   attribute: .centerY,
                                                   relatedBy: .equal,
                                                   toItem: view,
                                                   attribute: .centerY,
                                                   multiplier: 1.0,
                                                   constant: 0.0)
        let widthConstraint = NSLayoutConstraint(item: mostCompatibleLabel,
                                                 attribute: .width,
                                                 relatedBy: .equal,
                                                 toItem: nil,
                                                 attribute: .notAnAttribute,
                                                 multiplier: 1.0,
                                                 constant: 330.0)  // Adjust as needed
        
        let heightConstraint = NSLayoutConstraint(item: mostCompatibleLabel,
                                                  attribute: .height,
                                                  relatedBy: .equal,
                                                  toItem: nil,
                                                  attribute: .notAnAttribute,
                                                  multiplier: 1.0,
                                                  constant: 170.0)
        
        view.addConstraints([centerXConstraint, centerYConstraint, widthConstraint, heightConstraint])
        
        calculateButton.frame.origin.x = (self.view.frame.width / 2) - (calculateButton.frame.size.width / 2)
        calculateButton.frame.origin.y = mostCompatibleLabel.frame.origin.y + mostCompatibleLabel.frame.height + 40
        
        startLocationServices()
        loadUserProfile()
        
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "arrow25"), style: .plain, target: self, action: #selector(popVC))
        
        mostCompatibleTable.delegate = self
        mostCompatibleTable.dataSource = self
        mostCompatibleTable.rowHeight = 160.0
        
        mostCompatibleTable.register(UINib(nibName: "DatePlanCell", bundle: nil), forCellReuseIdentifier: "datePlanCell")
        
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
        
    }
    
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
    
    @objc func popVC() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func matchesPressed(_ sender: UIButton) {
        
        performSegue(withIdentifier: "availableMatchesSeg", sender: self)
    }
    
    @IBAction func calculatePressed(_ sender: UIButton) {
        
        if checkLocationAuthorisation() == "OK" {
            if myProfile.interests.count >= 5 {
                getMyLocation()
                dataLoading()
                
            } else {
                
                let notEnoughInterestsAlert = UIAlertController(title: "Uh-oh", message: "Your profile needs to include at least five interests in order to use Most Compatible. Come back once you've added some more!", preferredStyle: .alert)
                let okayAction = UIAlertAction(title: "Okay", style: .default)
                notEnoughInterestsAlert.addAction(okayAction)
                present(notEnoughInterestsAlert, animated: true)
            }
        } else {
            showAlert(title: "Uh-oh", message: "It seems you haven't given Just Friends permission to access your location. Please go to 'Settings', 'Just Friends', and then 'Location', in order to do so.")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "availableMatchesSeg" {
            
            let destinationVC = segue.destination as! MatchesViewController
            
            ownMatchStatus.name = self.myProfile.name
            ownMatchStatus.imageURL = self.myProfile.profilePicURL
            ownMatchStatus.ID = firebaseID
            ownMatchStatus.age = self.myProfile.age
            ownMatchStatus.gender = self.myProfile.gender
            ownMatchStatus.accepted = false
            ownMatchStatus.fcmToken = UserDefaults.standard.object(forKey: "fcmToken") as! String
            
            destinationVC.ownMatch = ownMatchStatus
        }
        
        if segue.identifier == "compatibleMatchProfileSeg" {
            
            let destinationVC = segue.destination as! MatchProfileViewController
            destinationVC.matchID = passedMatchProfile.userID
        }
    }
    
    func getMyLocation() {
        myLocation = CLLocation(latitude: locationManager.location?.coordinate.latitude ?? 0.0, longitude: locationManager.location?.coordinate.longitude ?? 0.0)
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
    
    func showAlert(title: String, message: String) {
        
        let enterValidDetailsAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Okay", style: .default)
        enterValidDetailsAlert.addAction(okayAction)
        self.present(enterValidDetailsAlert, animated: true)
    }
    
    func dataLoading() {
        
        Task.init {
            do {
                await loadExpiringMatches()
                expiringMatchesArray = await filterExpiringMatches(matches: expiringMatchesArray)
                await loadProfiles()
                print("profiles count1: \(profilesArray.count)")
                for prof in profilesArray {
                    print("1 id: \(prof.userID), \(prof.name)")
                }
                profilesArray = removeExpiringAndBlocked(profiles: profilesArray)
                print("profiles count2: \(profilesArray.count)")
                for prof in profilesArray {
                    print("2 id: \(prof.userID), \(prof.name)")
                }
                profilesArray = await calculateMostCompatible(profiles: profilesArray)
                print("profiles count3: \(profilesArray.count)")
                for prof in profilesArray {
                    print("3 id: \(prof.userID), \(prof.name)")
                }
                //                self.dataLoadedArray.append(true)
                self.mostCompatibleTable.reloadData()
                self.showShareAlert()
            } catch {
                print(error)
            }
            
        }
        
    }
    
    func loadUserProfile() {
        
        if let currentUser = Auth.auth().currentUser {
            firebaseID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
        
        guard let realm = RealmManager.getRealm() else {return}
        
        if let realmProfile = realm.objects(RProfile.self).filter("userID == %@", firebaseID).first {
            
            self.myProfile = realmProfile
        }
    }
    
    func loadProfiles() async {
        
        profilesArray = []
        
        if let currentUser = Auth.auth().currentUser {
            firebaseID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
        
        let currentCollection = db.collection("users")
        
        do {
            
            let querySnapshot = try await currentCollection.getDocuments()
            
            for doc in querySnapshot.documents {
                print("how many docs?")
                await loadIndividualProfile(userDocument: doc)
            }
        } catch {
            print(error)
        }
        
    }
    
    func loadIndividualProfile(userDocument: QueryDocumentSnapshot) async {
        
        let userID = userDocument.documentID
        print("individual profile load ran for \(userID)")
        
        let userCollection = db.collection("users").document(userID).collection("profile")
        
        do {
            let querySnapshot = try await userCollection.getDocuments()
            
            for doc in querySnapshot.documents {
                
                let data = doc.data()
                
                if let interests = data["interests"] as? [String] {
                    print("and got interests")
                    let interestsList = List<String>()
                    interests.forEach { interestsList.append($0) }
                    if interestsList.count >= 5 {
                        print("and saved them cos over 5")
                        guard let realm = RealmManager.getRealm() else {return}
                        
                        let userProfile = RCompatible()
                        
                        if let age = data["age"] as? Int, let gender = data["gender"] as? String, let name = data["name"] as? String, let picture = data["picture"] as? String, let userID = data["userID"] as? String, let profilePicRef = data["profilePicRef"] as? String {
                            
                            try! realm.write {
                                userProfile.age = age
                                userProfile.gender = gender
                                userProfile.name = name
                                userProfile.userID = userID
                                userProfile.profilePicRef = profilePicRef
                                userProfile.profilePicURL = picture
                                userProfile.interests = interestsList
                                if let town = data["town"] as? String {
                                    userProfile.town = town
                                }
                                if let profession = data["occupation"] as? String {
                                    userProfile.occupation = profession
                                }
                                if let summary = data["summary"] as? String {
                                    userProfile.summary = summary
                                }
                                profilesArray.append(userProfile)
                            }
                        }
                    }
                }
            }
        } catch {
            print("got a bloody error: \(error)")
        }
    }
    
    func removeExpiringAndBlocked(profiles: [RCompatible]) -> [RCompatible] {
        
        var expiredIDs: [String] = []
        var returnArray = profiles
        
        for id in expiringMatchesArray {
            expiredIDs.append(id.userID)
        }
        
        for (index, profile) in profiles.enumerated() {
            if expiredIDs.contains(profile.userID) {
                returnArray.remove(at: index)
            }
        }
        guard let realm = RealmManager.getRealm() else {return returnArray}
        
        let blockUsers = realm.objects(BlockedUser.self).filter("userID == %@", firebaseID)
        
        let blockedIDs = blockUsers.map { $0.blockID }
        
        for (index, profile) in returnArray.enumerated() {
            if blockedIDs.contains(profile.userID) {
                returnArray.remove(at: index)
            }
        }
        return returnArray
    }
    
    func calculateMostCompatible(profiles: [RCompatible]) async -> [RCompatible] {
        
        var returnArray: [RCompatible] = []
        
        var fiveInterests: [RCompatible] = []
        var fourInterests: [RCompatible] = []
        var threeInterests: [RCompatible] = []
        var twoInterests: [RCompatible] = []
        var oneInterests: [RCompatible] = []
        var zeroInterests: [RCompatible] = []
        
        for user in profiles {
            if user.userID == myProfile.userID { continue } // Skip current user
            
            let commonInterests = Set(myProfile.interests).intersection(user.interests)
            let commonInterestsCount = commonInterests.count
            
            switch commonInterestsCount {
            case 5:
                fiveInterests.append(user)
            case 4:
                fourInterests.append(user)
            case 3:
                threeInterests.append(user)
            case 2:
                twoInterests.append(user)
            case 1:
                oneInterests.append(user)
            case 0:
                zeroInterests.append(user)
            default:
                zeroInterests.append(user)
            }
        }
        
        if fiveInterests.count > 0 {
            fiveInterests = await sortByLocation(fiveInterests)
            for user in fiveInterests {
                if returnArray.count == 5 { break }
                returnArray.append(user)
            }
        }
        if returnArray.count < 5 {
            
            if fourInterests.count > 0 {
                fourInterests = await sortByLocation(fourInterests)
                for user in fourInterests {
                    if returnArray.count == 5 { break }
                    returnArray.append(user)
                }
            }
            
        }
        if returnArray.count < 5 {
            
            if threeInterests.count > 0 {
                threeInterests = await sortByLocation(threeInterests)
                for user in threeInterests {
                    if returnArray.count == 5 { break }
                    returnArray.append(user)
                }
            }
            
        }
        if returnArray.count < 5 {
            
            if twoInterests.count > 0 {
                twoInterests = await sortByLocation(twoInterests)
                for user in twoInterests {
                    if returnArray.count == 5 { break }
                    returnArray.append(user)
                }
            }
            
        }
        if returnArray.count < 5 {
            
            if oneInterests.count > 0 {
                oneInterests = await sortByLocation(oneInterests)
                for user in oneInterests {
                    if returnArray.count == 5 { break }
                    returnArray.append(user)
                }
            }
            
        }
        if returnArray.count < 5 {
            
            if zeroInterests.count > 0 {
                zeroInterests = await sortByLocation(zeroInterests)
                for user in zeroInterests {
                    if returnArray.count == 5 { break }
                    returnArray.append(user)
                }
            }
            
        }
        return returnArray
    }
    
    func sortByLocation(_ profiles: [RCompatible]) async -> [RCompatible] {
        
        var returnArray: [RCompatible] = []
        var locations: [CLLocation] = []
        var ids: [String] = []
        for profile in profiles {
            ids.append(profile.userID)
        }
        
        let currentCollection = db.collection("statuses")
        let query = currentCollection.whereField("userID", in: ids)
        
        do {
            
            let querySnapshot = try await query.getDocuments()
            
            var userIdToDocument: [String: DocumentSnapshot] = [:]
            
            for doc in querySnapshot.documents {
                let data = doc.data()
                if let userID = data["userID"] as? String {
                    userIdToDocument[userID] = doc
                }
            }
            
            for id in ids {
                if let doc = userIdToDocument[id] {
                    let data = doc.data()
                    if let latitude = data?["latitude"] as? Double, let longitude = data?["longitude"] as? Double {
                        
                        let newLocation = CLLocation(latitude: latitude, longitude: longitude)
                        locations.append(newLocation)
                    }
                }
            }
            
            let locationPairs = zip(locations, profiles).map { (location: $0.0, profile: $0.1) }
            let sortedPairs = locationPairs.sorted { (pair1, pair2) -> Bool in
                let distance1 = pair1.location.distance(from: myLocation)
                let distance2 = pair2.location.distance(from: myLocation)
                return distance1 < distance2
            }
            returnArray = sortedPairs.map { $0.profile }
            
        } catch {
            print("error getting statuses: \(error)")
        }
        return returnArray
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
            if timeInterval > TimeInterval(2 * 60) {
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

extension MostCompatibleViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        mostCompatibleLabel.isHidden = !profilesArray.isEmpty
        calculateButton.isHidden = !profilesArray.isEmpty
        
        return (profilesArray.count)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var returnCell: UITableViewCell?
        
        let cell = mostCompatibleTable.dequeueReusableCell(withIdentifier: "datePlanCell", for: indexPath) as! DatePlanCell
        
        cell.delegate = self
        cell.indexPath = indexPath
        cell.acceptedButton.isHidden = true
        cell.rejectedButton.isHidden = true
        cell.profilePicture.layer.cornerRadius = cell.profilePicture.frame.width / 2
        cell.profilePicture.clipsToBounds = true
        
        cell.datePlanLabel.text = "\(self.profilesArray[indexPath.row].name)"
        cell.ageLabel.text = String(self.profilesArray[indexPath.row].age)
        cell.genderLabel.image = UIImage(named: "big male")
        if self.profilesArray[indexPath.row].gender == "female" {
            cell.genderLabel.image = UIImage(named: "big female")
        }
        
        DispatchQueue.main.async {
            if let url = URL(string: self.profilesArray[indexPath.row].profilePicURL) {
                cell.profilePicture.kf.setImage(with: url)
            }
        }
        
        returnCell = cell
        
        return returnCell!
    }
}

//MARK: - TableView Delegate Methods

extension MostCompatibleViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150.0
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
                    await matchWithUser(indexPath: indexPath)
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
            if match.userID == profilesArray[indexPath.row].userID {
                return true
            }
        }
        return false
    }
    
    func matchWithUser(indexPath: IndexPath) async {
        
        guard let realm = RealmManager.getRealm() else {return}
        
        let daterID = profilesArray[indexPath.row].userID
        let dateName = myProfile.name
        
        let docRef1 = db.collection("statuses").whereField("userID", isEqualTo: daterID)
        do {
            let docs = try await docRef1.getDocuments()
            if docs.count > 0 {
                
                for doc in docs.documents {
                    
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
                        "name" : self.myProfile.name,
                        "imageURL" : self.myProfile.profilePicURL,
                        "activity" : "none",
                        "time" : "none",
                        "ID" : firebaseID,
                        "age" : self.myProfile.age,
                        "gender" : self.myProfile.gender,
                        "accepted" : false,
                        "fcmToken" : UserDefaults.standard.object(forKey: "fcmToken"),
                        "realmID" : UUID().uuidString,
                        "ownUserID" : daterID,
                        "chatID" : "none"
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
                    let docRef = db.collection("statuses").document(doc.documentID)
                    docRef.updateData(["suitorID" : firebaseID]) { err in
                        if let err = err {
                            print("error updating field: \(err)")
                        } else {
                            print("success")
                        }
                        
                    }
                    
                    docRef.addSnapshotListener { documentSnapshot, error in
                        guard let doccy = documentSnapshot else {
                            print("Error fetching document: \(error!)")
                            return
                        }
                        guard let field = doccy.data()?["suitorID"] as? String else {
                            print("Field does not exist")
                            return
                        }
                        
                        let myFunctions = Functions.functions()
                        let passedID = doccy.data()?["fcmToken"] as? String
                        
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
                    self.profilesArray.remove(at: indexPath.row)
                    self.mostCompatibleTable.reloadData()
                }
            } else {
                let userDoesNotExistAlert = UIAlertController(title: "Uh-oh", message: "Unfortunately this user is no longer available.", preferredStyle: .alert)
                let okayAction = UIAlertAction(title: "Okay", style: .default)
                userDoesNotExistAlert.addAction(okayAction)
                present(userDoesNotExistAlert, animated: true)
            }
            
        } catch {
            print("errrrror: \(error)")
        }
    }
}


extension MostCompatibleViewController: CustomTableViewCellDelegate {
    
    
    func customTableViewCellDidTapButton(_ cell: DatePlanCell, indexPath: IndexPath, buttonName: String) async {
        
        if buttonName == "viewProfileButton" {
            
            passedMatchProfile.age = profilesArray[indexPath.row].age
            passedMatchProfile.name = profilesArray[indexPath.row].name
            passedMatchProfile.gender = profilesArray[indexPath.row].gender
            passedMatchProfile.picture = profilesArray[indexPath.row].profilePicURL
            passedMatchProfile.userID = profilesArray[indexPath.row].userID
            
            performSegue(withIdentifier: "compatibleMatchProfileSeg", sender: self)
        }
    }
    
}

extension MostCompatibleViewController: CLLocationManagerDelegate {
    
    func checkLocationAuthorisation() -> String {
        let locationManager = CLLocationManager()
        
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse, .authorized:
            return "OK"
        case .notDetermined, .denied, .restricted:
            return "not OK"
        default:
            return "OK"
        }
    }
    
    
    func startLocationServices() {
        
        locationManager.delegate = self
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            
        } else {
            
            locationManager.startUpdatingLocation()
            
            guard let currentLocation = locationManager.location else { return }
            
        }
    }
    
}
