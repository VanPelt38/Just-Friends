//
//  DatePlanViewController.swift
//  BestLife
//
//  Created by Jake Gordon on 15/12/2022.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import CoreLocation

class DatePlanViewController: UIViewController {
    
    @IBOutlet weak var activityTextField: UITextField!
    @IBOutlet weak var timePicker: UIPickerView!
    @IBOutlet weak var seeAvailableButton: UIButton!
    var datePlanModel = DatePlanModel()
    
    private let possibleDates = ["today", "tonight", "tomorrow"]
    private var timeChosen = "none"
    var firebaseID = ""
    let locationManager = CLLocationManager()
   
    
    private let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       startLocationServices()
        
        seeAvailableButton.layer.cornerRadius = seeAvailableButton.frame.height / 2
        
        if let currentUser = Auth.auth().currentUser {
            firebaseID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
            
        timePicker.delegate = self
        activityTextField.delegate = self

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    
    @IBAction func seePartnersPressed(_ sender: UIButton) {
        
        if timeChosen == "none" {
            timeChosen = "today"
        }
        
        if activityTextField.text != "" && timeChosen != "none" {
            
            var docsArray: [QueryDocumentSnapshot] = []
            let userID = UserDefaults.standard.object(forKey: "uniqueID")
            
            let activity = activityTextField.text
            
            
            DispatchQueue.main.async { [self] in
                
                let currentCollection = db.collection("statuses")
                let query = currentCollection.whereField("userID", isEqualTo: firebaseID)
                
                query.getDocuments { [self] querySnapshot, err in
                    
                    if let err = err {
                        print("Error getting docs: \(err)")
                    } else {
                        
                        for doc in querySnapshot!.documents {
                            
                            docsArray.append(doc)
                            
                        }
                    }
                    
                    if let safeActivity = activity, let user = Auth.auth().currentUser?.email {
                        
                        guard let realm = RealmManager.getRealm() else {return}
                        
                        try! realm.write {
                            let realmStatus = RStatus()
                            realmStatus.id = firebaseID
                            realmStatus.dateActivity = safeActivity
                            realmStatus.dateTime = timeChosen
                            realmStatus.fcmToken = UserDefaults.standard.object(forKey: "fcmToken") as! String
                            realmStatus.latitude = locationManager.location?.coordinate.latitude ?? 0.0
                            realmStatus.longitued = locationManager.location?.coordinate.longitude ?? 0.0
                            realm.add(realmStatus, update: .all)
                        }
                        
                        if docsArray.count == 0 {
                            
                            
                            db.collection("statuses").addDocument(data: [
                                "activity": safeActivity,
                                "time": timeChosen,
                                "userID": firebaseID,
                                "fcmToken": UserDefaults.standard.object(forKey: "fcmToken"),
                                "latitude": locationManager.location?.coordinate.latitude,
                                "longitude": locationManager.location?.coordinate.longitude
                            ]) { (error) in
                                
                                if let e = error {
                                    print("There was an issue saving data to firestore, \(e)")
                                } else {
                                    
                                    print("Successfully saved data.")
                                    
                                }
                                
                                
                            }
                            
                            
                            
                        } else {
                            
                            let docname = docsArray[0].documentID
                            db.collection("statuses").document(docname).setData([
                                "activity": safeActivity,
                                "time": timeChosen,
                                "userID": firebaseID,
                                "fcmToken": UserDefaults.standard.object(forKey: "fcmToken"),
                                "latitude": locationManager.location?.coordinate.latitude,
                                "longitude": locationManager.location?.coordinate.longitude
                            ]) { err in
                                
                                if let err = err {
                                    print("error writing doc: \(err)")
                                } else {
                                    print("doc written successfully.")
                                }
                            }
                            
                        }
                    }
                }
                
                
                
            }
            
            datePlanModel.dateActivity = activityTextField.text!
            datePlanModel.dateTime = timeChosen
            activityTextField.text = ""
            
            
            performSegue(withIdentifier: "dateAvailableSeg", sender: self)
        } else {
            
            showAlert(title: "Uh oh", message: "Please select a time and activity!")
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "dateAvailableSeg" {
            
            if let safeLocation = locationManager.location {
                
                let destinationVC = segue.destination as! AvailableDatesViewController
                destinationVC.dateActivity = datePlanModel.dateActivity
                destinationVC.dateTime = datePlanModel.dateTime
                destinationVC.location = safeLocation
            }
            
        }
    }
    
    func showAlert(title: String, message: String) {
        
        let enterValidDetailsAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Okay", style: .default)
        enterValidDetailsAlert.addAction(okayAction)
        self.present(enterValidDetailsAlert, animated: true)
    }
   
}

//MARK: - TextField Delegate Methods

extension DatePlanViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    
        activityTextField.endEditing(true)
        return true
        
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        
        activityTextField.resignFirstResponder()
        activityTextField.endEditing(true)
        
    }
}

//MARK: - PickerView Delegate Methods

extension DatePlanViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return possibleDates.count
    }
}

extension DatePlanViewController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return possibleDates[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        timeChosen = possibleDates[row]
        
    }
    
}


extension DatePlanViewController: CLLocationManagerDelegate {
    
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
