//
//  ProfileSetUpViewController.swift
//  BestLife
//
//  Created by Jake Gordon on 02/05/2023.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers
import FirebaseStorage
import FirebaseAuth
import FirebaseFirestore

class ProfileSetUpViewController: UIViewController {
    
    @IBOutlet weak var profileImage: UIImageView!
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var ageDatePicker: UIDatePicker!
    
    @IBOutlet weak var maleCheck: UIImageView!
    
    @IBOutlet weak var femaleCheck: UIImageView!
    
    var isImageChosen = false
    var isAgeChosen = false
    var gender: String?
    var imageString: String?
    var userID: String?
    var imageExtension = ""
    private let db = Firestore.firestore()
    var profilePicRef = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let currentUser = Auth.auth().currentUser {
            userID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
        
       setUpDatePicker()
        
        maleCheck.isHidden = true
        femaleCheck.isHidden = true

        nameTextField.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @IBAction func addProfilePhotoPressed(_ sender: UIButton) {
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.mediaTypes = [UTType.image.identifier]
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func maleButtonChecked(_ sender: UIButton) {
        
        femaleCheck.isHidden = true
        maleCheck.isHidden = false
        gender = "male"
    }
    
    @IBAction func femaleButtonChecked(_ sender: UIButton) {
        
        femaleCheck.isHidden = false
        maleCheck.isHidden = true
        gender = "female"
    }
    
    
    @IBAction func profileCompletePressed(_ sender: UIButton) {
        
        if isImageChosen == true && nameTextField.text != "" && isAgeChosen == true && gender != nil {

            if let userName = nameTextField.text, let image = profileImage.image, let userGender = gender, let id = userID {
 
                    Task.init {
                        imageString = await uploadImageToFireStorage(picture: image)
                        
                        let realmProfile = RProfile()
                        realmProfile.age = calculatedAge(date: ageDatePicker.date)
                        realmProfile.gender = userGender
                        realmProfile.name = userName
                        realmProfile.picture = convertImageToData(image: image)
                        realmProfile.userID = id
                        persistProfileLocally(realmProfile: realmProfile)
                        
                        await saveProfile(userName: userName, imageURL: imageString ?? "none", age: calculatedAge(date: ageDatePicker.date), userGender: userGender, id: id)
                        await flagProfileSetUp(id: id)
                        self.performSegue(withIdentifier: "profileSetUpHomeSeg", sender: self)
                    }
                }
        } else {
            
            let alert = UIAlertController(title: "Profile Incomplete!", message: "Please fill out everything before proceeding.", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Okay", style: .default)
            alert.addAction(okayAction)
            present(alert, animated: true, completion: nil)
        }
    }
    
    func convertImageToData(image: UIImage) -> Data {
        
        if imageExtension == "jpg" || imageExtension == "jpeg" {
            return image.jpegData(compressionQuality: 0.8)!
        } else if imageExtension == "png" {
            return image.pngData()!
        } else {
            print("unsupported image type")
            return image.pngData()!
        }
    }
    
    func persistProfileLocally(realmProfile: RProfile) {
        
        guard let realm = RealmManager.getRealm() else { return }
        try! realm.write {
            realm.add(realmProfile)
        }
        
    }
    
    func saveProfile(userName: String, imageURL: String, age: Int, userGender: String, id: String) async {
        
        do {
            try await db.collection("users").document(id).collection("profile").document("profile").setData([
                "age": age,
                "gender": userGender,
                "name": userName,
                "picture": imageURL,
                "userID": id,
                "profilePicRef": profilePicRef
            ])
        } catch {
            print("There was an issue saving data to firestore, \(error)")
        }
    }
    
    func flagProfileSetUp(id: String) async {
        
        let userCollection = self.db.collection("users").document(id).collection("registration").document(id)
        do {
            try await userCollection.setData([
                "profileSetUp" : true
            ])
        } catch {
            print(error)
        }
    }
    
   
    func uploadImageToFireStorage(picture: UIImage) async -> String {
        guard let imageData = picture.jpegData(compressionQuality: 0.8) else {
            return "Failed to convert image to data."
        }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imageFileName = "\(UUID().uuidString).jpg"
        profilePicRef = imageFileName
        let imageRef = storageRef.child("images/\(imageFileName)")
        
        do {
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            _ = try await imageRef.putDataAsync(imageData, metadata: metadata)
            let downloadURL = try await imageRef.downloadURL()
            return downloadURL.absoluteString
        } catch {
             return "failed to retrieve download url: \(error)"
        }
        
    }
    
    func setUpDatePicker() {
        ageDatePicker.datePickerMode = .date
        ageDatePicker.locale = Locale(identifier: "en_GB")
        ageDatePicker.minimumDate = Calendar.current.date(byAdding: .year, value: -150, to: Date())
        ageDatePicker.maximumDate = Calendar.current.date(byAdding: .year, value: -18, to: Date())
        ageDatePicker.addTarget(self, action: #selector(didPickDate), for: .valueChanged)
    }
    
    @objc func didPickDate() {
        isAgeChosen = true
    }
    
    func calculatedAge(date: Date) -> Int {
        
        var age = 0
        
        let calendar = Calendar.current
        let currentDate = Date()
        let dateComponents = calendar.dateComponents([.year], from: date, to: currentDate)
        if let years = dateComponents.year {
            age = abs(years)
            print("Age: \(age)")
        }
        return age
    }
    
}

extension ProfileSetUpViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let pickedImage = info[.originalImage] as? UIImage {
            
            profileImage.image = pickedImage
            
            let photoPath = info[UIImagePickerController.InfoKey.referenceURL] as! NSURL
            if let path = photoPath.absoluteString {
                if path.hasSuffix("JPG") {
                    print("jpg")
                    imageExtension = "jpg"
                } else if path.hasSuffix("PNG") {
                    print("png")
                    imageExtension = "png"
                } else if path.hasSuffix("JPEG") {
                    print("jpeg")
                    imageExtension = "jpeg"
                } else {
                    print("unsupported image type")
                }
                    }
            
            picker.dismiss(animated: true, completion: nil)
            isImageChosen = true
        }
    }
}

extension ProfileSetUpViewController: UINavigationControllerDelegate {
    
    
}

extension ProfileSetUpViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    
        nameTextField.endEditing(true)
        return true
        
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        
        nameTextField.resignFirstResponder()
        nameTextField.endEditing(true)
    }

}
