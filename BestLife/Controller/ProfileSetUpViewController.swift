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
    @IBOutlet weak var readyButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var maleButton: UIButton!
    @IBOutlet weak var femaleButton: UIButton!
    
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
        setUpUI()

        nameTextField.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    func setUpUI() {
        
        profileImage.clipsToBounds = true
        profileImage.layer.cornerRadius = profileImage.frame.size.width / 2
        profileImage.tintColor = UIColor(red: 0.075, green: 0, blue: 0.557, alpha: 1.0)
        readyButton.clipsToBounds = true
        readyButton.layer.cornerRadius = readyButton.frame.height / 2
        let constraint = NSLayoutConstraint(item: cameraButton, attribute: .centerY, relatedBy: .equal, toItem: profileImage, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        self.view.addConstraint(constraint)
        cameraButton.clipsToBounds = true
        cameraButton.setContentHuggingPriority(.defaultLow, for: .vertical)
        cameraButton.layer.cornerRadius = cameraButton.frame.size.width / 2
        
        let image = UIImage(systemName: "checkmark")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
        let unselectedImage = UIImage(systemName: "checkmark")?.withTintColor(.systemGray, renderingMode: .alwaysOriginal)
      
        femaleButton.setImage(image, for: .selected)
        maleButton.setImage(unselectedImage, for: .normal)
        femaleButton.setImage(unselectedImage, for: .normal)
        maleButton.setImage(image, for: .selected)
    }
    
    @IBAction func addProfilePhotoPressed(_ sender: UIButton) {
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.mediaTypes = [UTType.image.identifier]
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func maleButtonChecked(_ sender: UIButton) {
        maleButton.isSelected = true
        femaleButton.isSelected = false
        gender = "male"
    }
    
    @IBAction func femaleButtonChecked(_ sender: UIButton) {
        femaleButton.isSelected = true
        maleButton.isSelected = false
        gender = "female"
    }
    
    
    @IBAction func profileCompletePressed(_ sender: UIButton) {
        
        if isImageChosen == true && nameTextField.text != "" && isAgeChosen == true && gender != nil {
            if imageExtension != "unsupported" {
                if let userName = nameTextField.text, let image = profileImage.image, let userGender = gender, let id = userID {
                
                Task.init {
                    
                    let dataPic = convertImageToData(image: image)
                    if dataPic.count < 16000000 {
                        
                        imageString = await uploadImageToFireStorage(picture: image)
                        
                        let realmProfile = RProfile()
                        realmProfile.age = calculatedAge(date: ageDatePicker.date)
                        realmProfile.gender = userGender
                        realmProfile.name = userName
                        realmProfile.picture = dataPic
                        realmProfile.profilePicURL = imageString ?? "none"
                        realmProfile.userID = id
                        persistProfileLocally(realmProfile: realmProfile)
                        
                        await saveProfile(userName: userName, imageURL: imageString ?? "none", age: calculatedAge(date: ageDatePicker.date), userGender: userGender, id: id)
                        await flagProfileSetUp(id: id)
                        self.performSegue(withIdentifier: "profileSetUpHomeSeg", sender: self)
                    } else {
                        let imageTooBigAlert = UIAlertController(title: "Uh-oh", message: "The image you've chosen is too big - please pick one with a file size under 16Mb.", preferredStyle: .alert)
                        let okayAction = UIAlertAction(title: "Okay", style: .default)
                        imageTooBigAlert.addAction(okayAction)
                        present(imageTooBigAlert, animated: true, completion: nil)
                    }
                }
            }
            } else {
                let badImageAlert = UIAlertController(title: "Uh-oh", message: "We're sorry but the image file you've chosen is unsupported - please use images with the following extensions: heic, jpeg, jpg, png.", preferredStyle: .alert)
                let okayAction = UIAlertAction(title: "Okay", style: .default)
                badImageAlert.addAction(okayAction)
                present(badImageAlert, animated: true, completion: nil)
            }
        } else {
            
            let alert = UIAlertController(title: "Profile Incomplete", message: "Please enter all your details before proceeding.", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Okay", style: .default)
            alert.addAction(okayAction)
            present(alert, animated: true, completion: nil)
        }
    }
    
    func convertImageToData(image: UIImage) -> Data {
        
        if imageExtension.lowercased() == "jpg" || imageExtension.lowercased() == "jpeg" || imageExtension.lowercased() == "png" {
            print("got \(imageExtension.lowercased())")
            return image.jpegData(compressionQuality: 0.8)!
        } else if imageExtension.lowercased() == "heic" {
            print("got heic")
            let options: [CFString: Any] = [
                kCGImageDestinationLossyCompressionQuality: 0.8
            ]
            let mutableData = NSMutableData()
            guard let imageDestination = CGImageDestinationCreateWithData(mutableData, kUTTypeJPEG, 1, nil) else {
                print("failed to finalise image destination.")
                return Data()
            }
            CGImageDestinationAddImage(imageDestination, image.cgImage!, options as CFDictionary)
            guard CGImageDestinationFinalize(imageDestination) else {
                print("failed to finalise image destination")
                return Data()
            }
            return mutableData as Data
        } else {
            print("unsupported image type")
            return image.jpegData(compressionQuality: 0.8)!
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
                if path.hasSuffix("JPG") || path.hasSuffix("jpg") {
                    print("jpg")
                    imageExtension = "jpg"
                } else if path.hasSuffix("PNG") || path.hasSuffix("png") {
                    print("png")
                    imageExtension = "png"
                } else if path.hasSuffix("JPEG") || path.hasSuffix("jpeg") {
                    print("jpeg")
                    imageExtension = "jpeg"
                } else if path.hasSuffix("HEIC") || path.hasSuffix("heic") {
                    print("heic")
                    imageExtension = "heic"
                } else {
                    print("unsupported image type")
                    imageExtension = "unsupported"
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
