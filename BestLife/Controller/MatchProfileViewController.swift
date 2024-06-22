//
//  MatchProfileViewController.swift
//  BestLife
//
//  Created by Jake Gordon on 08/07/2023.
//

import UIKit
import Kingfisher
import Eureka
import FirebaseAuth
import FirebaseFirestore
import RealmSwift

class MatchProfileViewController: FormViewController {
    
    @IBOutlet weak var matchProfilePicture: UIImageView!
    
    var matchID: String?
    var profileDetailsArray: [String] = []
    var isFormCreated = false
    var titleLabel = UILabel()
    var profile = RMatchModel()
    var firebaseID: String?
    private let db = Firestore.firestore()
    var profilePicBottomPoint: Double?
    var genderImage = UIImageView()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getLocalProfile()
        setUpUI()
        Task.init {
            await setupProfile()
            updateFormValues()
        }

        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupTableView()
        updateFormValues()

            titleLabel.text = "\(self.profile.age)"
            if let town = self.profile.town {
                titleLabel.text?.append(", \(town)")
                if let occupation = self.profile.occupation {
                    titleLabel.text?.append(", \(occupation)")
                }
            }

    }

    
    @objc func popVC() {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !isFormCreated {
            createProfileDetailsForm()
        }
        profilePicSize()
    }
    
    func updateFormValues() {
        
        if let summaryRow = form.rowBy(tag: "summary") as? TextAreaRow {
            summaryRow.value = self.profile.summary
            summaryRow.updateCell()
        }
        if let interestsRow = form.rowBy(tag: "interests") as? TextAreaRow {
            interestsRow.value = createInterestsText()
            interestsRow.updateCell()
        }
            titleLabel.text = "\(self.profile.age)"
        if let town = self.profile.town {
            titleLabel.text?.append(", \(town)")
        }
        if let occupation = self.profile.occupation {
            titleLabel.text?.append(", \(occupation)")
        }
    }

    
    func setupTableView() {
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.frame.size = CGSize(width: self.view.frame.width - 20, height: 600)
        tableView.frame.origin.x = view.frame.origin.x + 10
        tableView.frame.origin.y = profilePicBottomPoint ?? 0.0
        tableView.backgroundColor = .clear
    }
    
    func profilePicSize() {
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            
            let size = CGSize(width: self.view.frame.width / 3, height: self.view.frame.width / 3)
            matchProfilePicture.frame.size = size
            matchProfilePicture.frame.origin.x = (self.view.frame.width / 2) - matchProfilePicture.frame.size.width / 2
            matchProfilePicture.frame.origin.y = (self.view.frame.height / 2) - matchProfilePicture.frame.size.height / 2
            matchProfilePicture.clipsToBounds = true
            matchProfilePicture.layer.cornerRadius = matchProfilePicture.frame.size.width / 2
            profilePicBottomPoint = (matchProfilePicture.frame.origin.y + matchProfilePicture.frame.size.height) + 50.0
            
        } else {
            
            let size = CGSize(width: self.view.frame.width, height: self.view.frame.width)
            matchProfilePicture.frame.size = size
            matchProfilePicture.frame.origin.y = 0
            matchProfilePicture.frame.origin.x = 0
            profilePicBottomPoint = (matchProfilePicture.frame.origin.y + matchProfilePicture.frame.size.height) + 50.0
        }
    }
    
    func setUpUI() {
        
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "arrow25"), style: .plain, target: self, action: #selector(popVC))
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.frame.size = CGSize(width: self.view.frame.width - 20, height: 230)
        profilePicSize()
    }
    
    func createInterestsText() -> String {
        
        var text = ""
        if !self.profile.interests.isEmpty {
            for (index, interest) in self.profile.interests.enumerated() {
                if index < self.profile.interests.count - 1 {
                    text.append("\(interest), ")
                } else {
                    text.append(interest)
                }
            }
        }
        return text
    }
    
    func createProfileDetailsForm() {
        
        isFormCreated = true

        tableView.separatorStyle = .none
        
        let section = Section("Hi there")
        form +++ section
        
        let headerView = UIView(frame: CGRect(x: tableView.bounds.origin.x, y: tableView.bounds.origin.y, width: tableView.bounds.width, height: 44))
        let curvePath = UIBezierPath(roundedRect: headerView.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 10, height: 10))
        let curveLayer = CAShapeLayer()
        curveLayer.path = curvePath.cgPath
        headerView.layer.mask = curveLayer
        headerView.backgroundColor = UIColor(red: 255/255, green: 204/255, blue: 204/255, alpha: 1.0)
        
        titleLabel = UILabel(frame: CGRect(x: headerView.bounds.origin.x, y: headerView.bounds.origin.y, width: headerView.bounds.width, height: 44))
        
            titleLabel.text = "\(self.profile.age)"
            if let town = self.profile.town {
                titleLabel.text?.append(", \(town)")
                if let occupation = self.profile.occupation {
                    titleLabel.text?.append(", \(occupation)")
                }
            }
        
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont(name: "Gill Sans Bold", size: 14)
        
        let separator = UIView()
        separator.backgroundColor = .lightGray
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        genderImage.translatesAutoresizingMaskIntoConstraints = false
        genderImage.image = (self.profile.gender == "male") ? UIImage(named: "big male") : UIImage(named: "big female")
        genderImage.widthAnchor.constraint(equalToConstant: 20).isActive = true
        genderImage.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        headerView.addSubview(separator)
        headerView.addSubview(genderImage)
        
        genderImage.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 12).isActive = true
        genderImage.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -12).isActive = true
        
        separator.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 8).isActive = true
        separator.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -8).isActive = true
        separator.bottomAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
        separator.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        
        headerView.addSubview(titleLabel)
        
        let head = HeaderFooterView<UIView>(.callback({
            return headerView
        }))
        section.header = head
        section <<< LabelRow() { row in
            row.title = "About me.."
            row.cell.textLabel?.font = UIFont(name: "Gill Sans Bold", size: 15)
            row.cell.height = { 35 }
            row.cell.backgroundColor = UIColor(red: 255/255, green: 204/255, blue: 204/255, alpha: 1.0)
        }
        section <<< TextAreaRow("summary") { row in
            row.placeholder = ""
            row.value = self.profile.summary
            row.disabled = true
            row.cell.textView.font = UIFont(name: "Gill Sans", size: 15)
            row.cell.backgroundColor = UIColor(red: 255/255, green: 204/255, blue: 204/255, alpha: 1.0)
            row.cell.textView.backgroundColor = .white
            row.cell.textView.layer.cornerRadius = 10
            row.cell.textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            row.cellUpdate { cell, row in
                cell.textView.textColor = .black
            }
        }
        section <<< LabelRow() { row in
            
            row.title = "My interests.."
            row.cell.backgroundColor = UIColor(red: 255/255, green: 204/255, blue: 204/255, alpha: 1.0)
            row.cell.height = { 35 }
            row.cell.textLabel?.font = UIFont(name: "Gill Sans Bold", size: 15)
        }
        section <<< TextAreaRow("interests") { row in
            row.placeholder = ""
            row.disabled = true
            row.value = createInterestsText()
            row.cell.textView.font = UIFont(name: "Gill Sans", size: 15)
            row.cell.backgroundColor = UIColor(red: 255/255, green: 204/255, blue: 204/255, alpha: 1.0)
            row.cell.textView.backgroundColor = .white
            row.cell.textView.layer.cornerRadius = 10
            row.cell.textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            row.cellUpdate { cell, row in
                cell.textView.textColor = .black
            }
        }
        
    }
    
    func getLocalProfile(){

         guard let realm = RealmManager.getRealm() else {return}
  
         if let rProfile = realm.objects(RMatchModel.self).filter("userID == %@", matchID).first {
             
            profile = rProfile
                 
                 self.navigationItem.title = profile.name
                 
             if let url = URL(string: profile.imageURL) {
                     
                     do {
                         try self.matchProfilePicture.kf.setImage(with: url)
                     } catch {
                         print("ERROR LOADING PROFILE IMAGE: \(error.localizedDescription)")
                     }
                 }
         }
    }
    
    func setupProfile() async {
        
        if let currentUser = Auth.auth().currentUser {
            firebaseID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
        
        guard let realm = RealmManager.getRealm() else {return}
        
        let currentCollection = db.collection("users").document(matchID ?? "").collection("profile")
        let query = currentCollection.whereField("userID", isEqualTo: matchID)
        do {
           let querySnapshot = try await query.getDocuments()

            for doc in querySnapshot.documents {
                
                let data = doc.data()
                
                try! realm.write {
                    
                    if let age = data["age"] as? Int, let gender = data["gender"] as? String, let name = data["name"] as? String, let picture = data["picture"] as? String, let userID = data["userID"] as? String, let profilePicRef = data["profilePicRef"] as? String {
                        print("this is name: \(name)")
                        profile.age = age
                        profile.gender = gender
                        profile.name = name
                        profile.userID = userID
                        
                        
                        if let town = data["town"] as? String {
                            profile.town = town
                        }
                        if let profession = data["occupation"] as? String {
                            profile.occupation = profession
                        }
                        if let summary = data["summary"] as? String {
                            profile.summary = summary
                        }
                        if let interests = data["interests"] as? [String] {
                            let interestsList = List<String>()
                            interests.forEach { interestsList.append($0) }
                            profile.interests = interestsList
                        }
                        print("profile now1: \(self.profile)")
                        DispatchQueue.main.async {
                            print("profile now: \(self.profile)")
                            self.navigationItem.title = name
                            self.genderImage.image = (self.profile.gender == "male") ? UIImage(named: "big male") : UIImage(named: "big female")
                            self.titleLabel.text = "\(age)"
                                if let town = data["town"] as? String {
                                    self.titleLabel.text?.append(", \(town)")
                                    if let occupation = self.profile.occupation {
                                        self.titleLabel.text?.append(", \(occupation)")
                                    }
                                }
                            
                            
                            if let url = URL(string: picture) {
                                
                                do {
                                    try self.matchProfilePicture.kf.setImage(with: url)
                                } catch {
                                    print("ERROR LOADING PROFILE IMAGE: \(error.localizedDescription)")
                                }
                                
                                self.tableView.reloadData()
                            }
                        }
                    }
                }
            }
        } catch {
            print("error loading user profile: \(error)")
        }
    }
  
}


