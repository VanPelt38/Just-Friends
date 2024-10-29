//
//  EditProfileViewController.swift
//  BestLife
//
//  Created by Jake Gordon on 06/05/2024.
//

import UIKit
import Eureka
import FirebaseAuth
import RealmSwift
import FirebaseFirestore
import MessageUI

class EditProfileViewController: FormViewController {
    
    var userID: String?
    let db = Firestore.firestore()
    var profile: RProfile?
    let fab = FAB()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "arrow25"), style: .plain, target: self, action: #selector(popVC))
        
        if let currentUser = Auth.auth().currentUser {
            userID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
        
        loadProfile()
        createProfileDetailsForm()
        setupFAB()
    }
    
    private func setupFAB() {
        
        fab.frame = CGRect(x: self.view.frame.width - 80, y: self.view.frame.height - 100, width: 60, height: 60)
        fab.addTarget(self, action: #selector(fabTapped), for: .touchUpInside)
        fab.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(fab)
        
        NSLayoutConstraint.activate([
            fab.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            fab.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            fab.widthAnchor.constraint(equalToConstant: 60),
            fab.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    @objc private func fabTapped() {
        sendEmailToDevelopers()
    }
    
    func sendEmailToDevelopers() {
        if MFMailComposeViewController.canSendMail() {
            
            let userID = Auth.auth().currentUser?.uid ?? "ID not found"
            let mailComposeVC = MFMailComposeViewController()
            mailComposeVC.mailComposeDelegate = self
            mailComposeVC.setToRecipients(["justfriendshelpdesk@gmail.com"])
            mailComposeVC.setSubject("Just Friends Support Issue")
            mailComposeVC.setMessageBody(
                "User ID: \(userID), Email: \(UserDefaults.standard.value(forKey: "email") ?? "Email not found"), Version: \(UIDevice.current.systemVersion)"
                , isHTML: false)
            present(mailComposeVC, animated: true, completion: nil)
        } else {
            self.showAlert(title: "Uh-oh", message: "Looks like your device doesn't have email configured. Please set it up and try again. You can also email us directly at justfriendshelpdesk@gmail.com .")
        }
    }
    
    func showAlert(title: String, message: String) {
        
        let enterValidDetailsAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Okay", style: .default)
        enterValidDetailsAlert.addAction(okayAction)
        self.present(enterValidDetailsAlert, animated: true)
    }
    
    @objc func popVC() {
        navigationController?.popViewController(animated: true)
    }
    
    func loadProfile() {
        
        self.profile = nil
        
        guard let realm = RealmManager.getRealm() else {return}
        
        if let prof = realm.objects(RProfile.self).filter("userID == %@", userID).first {
            self.profile = prof
        }
    }
    
    func createSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = .lightGray
        separator.alpha = 0.5
        separator.translatesAutoresizingMaskIntoConstraints = false
        return separator
    }
    
    func createProfileDetailsForm() {
        
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        let section = Section()
        form +++ section
        
        section <<< TextRow() { row in
            row.title = "My town:"
            row.tag = "town"
            row.placeholder = "..."
            row.cell.textLabel?.font = UIFont(name: "Gill Sans Bold", size: 17)
            row.value = self.profile?.town
        }.cellUpdate({ cell, row in
            cell.textField.font = UIFont(name: "Gill Sans", size: 17)
            cell.textField.textColor = self.profile?.town != nil ? .black : .lightGray
            let sep = self.createSeparator()
            cell.contentView.addSubview(sep)
            sep.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 24).isActive = true
            sep.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: 0).isActive = true
            sep.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor).isActive = true
            sep.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        })
        
        section <<< TextRow() { row in
            row.title = "My profession:"
            row.placeholder = "..."
            row.tag = "profession"
            row.cell.textLabel?.font = UIFont(name: "Gill Sans Bold", size: 17)
            row.value = self.profile?.occupation
        }.cellUpdate({ cell, row in
            cell.textField.font = UIFont(name: "Gill Sans", size: 17)
            cell.textField.textColor = self.profile?.occupation != nil ? .black : .lightGray
            let sep = self.createSeparator()
            cell.contentView.addSubview(sep)
            sep.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 24).isActive = true
            sep.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: 0).isActive = true
            sep.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor).isActive = true
            sep.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        })

        section <<< LabelRow() { row in
            row.title = "About me:"
            row.cell.textLabel?.font = UIFont(name: "Gill Sans Bold", size: 17)
            row.cell.height = { 35 }
        }
        section <<< TextAreaRow() { row in

            row.tag = "summary"
            row.placeholder = "..."
            row.value = self.profile?.summary
            row.cell.textView.font = UIFont(name: "Gill Sans", size: 17)
            row.cell.textView.backgroundColor = .white
            row.cell.textView.layer.cornerRadius = 10
            
        }.cellUpdate({ cell, row in
            cell.textView.textColor = self.profile?.summary != nil ? .black : .lightGray
            let sep = self.createSeparator()
            cell.contentView.addSubview(sep)
            sep.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 24).isActive = true
            sep.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: 0).isActive = true
            sep.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor).isActive = true
            sep.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        })
        
        let interestsSelectrow = MultipleSelectorRow<String>() { row in
            row.title = "My interests:"
            row.tag = "interests"
            row.cell.textLabel?.font = UIFont(name: "Gill Sans Bold", size: 17)
            row.presentationMode = .show(controllerProvider: ControllerProvider.callback(builder: {
                return CustomMultipleSelectorViewController()
            }), onDismiss: nil)
            
            if let i = self.profile?.interests {
                let interestsSet: Set<String> = Set(i)
                row.value = interestsSet
            }
            row.options = ["Sports", "Exercise", "Reading", "Foodie", "Nightlife", "Gardening", "Socialising", "Music", "Gaming", "Cinema", "Cooking", "Travelling", "Art", "Tech", "Photography", "Writing", "Walking", "Pubs"]
        }.cellUpdate { cell, row in
            cell.detailTextLabel?.font = UIFont(name: "Gill Sans", size: 17)
            let sep = self.createSeparator()
            cell.contentView.addSubview(sep)
            sep.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 24).isActive = true
            sep.widthAnchor.constraint(equalToConstant: self.view.frame.width).isActive = true
            sep.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor).isActive = true
            sep.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        }
        section <<< interestsSelectrow
        
        var selectedOptions: Set<String> = []
        var previouslySelectedOptions: Set<String> = []
        interestsSelectrow.onChange { [weak self] row in
            if row.value?.count ?? 0 > 5 {
                // Display an alert if the maximum number of selections is exceeded
                let newSet = row.value?.subtracting(previouslySelectedOptions)
                row.value?.remove(newSet!.first!)
                self?.navigationController?.popViewController(animated: true)
                let alertController = UIAlertController(title: "Uh-oh", message: "You can only select up to 5 interests.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alertController, animated: true, completion: nil)
            } else {
                previouslySelectedOptions = selectedOptions
                selectedOptions = Set(row.value ?? [])
            }
        }
        
        section <<< TextRow() { row in
          
        }.cellUpdate({ cell, row in
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: self.view.frame.width)
        })
        
        section <<< ButtonRow() { row in
            row.cell.textLabel?.font = UIFont(name: "Gill Sans Bold", size: 25)
            row.title = "Save My Profile"
        }.onCellSelection({ [self] cell, row in

            saveProfileDetails()
            let alertController = UIAlertController(title: "Success!", message: "Your profile has been updated.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        })
        .cellUpdate({ cell, row in
            row.cell.textLabel?.textColor = UIColor(red: 0.075, green: 0, blue: 0.557, alpha: 1.0)
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: self.view.frame.width)
        })

    }
    
    func saveProfileDetails() {
        
        guard let realm = RealmManager.getRealm() else { return }
        
        let profileDict = self.form.values() as [AnyHashable: Any]

        try! realm.write {
            if let userProfile = realm.object(ofType: RProfile.self, forPrimaryKey: userID) {
                
                if let town = profileDict["town"] {
                    userProfile.town = town as? String
                }
                if let occupation = profileDict["profession"] {
                    userProfile.occupation = occupation as? String
                }
                if let summary = profileDict["summary"] {
                    userProfile.summary = summary as? String
                }
                if let interests = profileDict["interests"] as? Set<String> {
                    let interestsList = List<String>()
                    interests.forEach { interestsList.append($0) }
                    userProfile.interests = interestsList
                }
            }
        }
        Task.init {
            await saveProfileToFireStore(profileDict)
        }
    }
    
    func saveProfileToFireStore(_ profileDict: [AnyHashable: Any]) async {
        
        let interestSet = profileDict["interests"] as? Set<String>
        let interests = Array<String>(interestSet!)
        
        do {

            try await db.collection("users").document(userID ?? "").collection("profile").document("profile").setData([
                "town" : profileDict["town"] as? String,
                "occupation" : profileDict["profession"] as? String,
                "summary" : profileDict["summary"] as? String,
                "interests": interests as? [String]
            ], merge: true)
        } catch {
            print("error persisting profile details to FireStore: \(error)")
        }

    }
}

extension EditProfileViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: (any Error)?) {
        
        switch result {
        case .saved:
            self.showToast(message: "Your draft has been saved!")
        case .sent:
            self.showToast(message: "Your message has been sent!")
        default:
            print("nutting")
        }
        
        controller.dismiss(animated: true)
    }
}
