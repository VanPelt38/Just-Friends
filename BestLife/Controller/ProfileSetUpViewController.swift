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
    
    @IBOutlet weak var ageTextField: UITextField!
    
    @IBOutlet weak var maleCheck: UIImageView!
    
    @IBOutlet weak var femaleCheck: UIImageView!
    
    var isImageChosen = false
    var gender: String?
    var imageString: String?
    var userID: String?
    private let db = Firestore.firestore()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let currentUser = Auth.auth().currentUser {
            userID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
        
       
        
        maleCheck.isHidden = true
        femaleCheck.isHidden = true

        nameTextField.delegate = self
        ageTextField.delegate = self
        
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
        
        if isImageChosen == true && nameTextField.text != "" && ageTextField.text != "" && gender != nil {
            
            
            DispatchQueue.main.async { [self] in
                
                if let userName = nameTextField.text, let imageURL = imageString, let age = ageTextField.text, let userGender = gender, let id = userID {
                   
                    db.collection("profiles").addDocument(data: [
                        "age": age,
                        "gender": userGender,
                        "name": userName,
                        "picture": imageURL,
                        "userID": id
                    ]) { (error) in
                        
                        if let e = error {
                            print("There was an issue saving data to firestore, \(e)")
                        } else {
                            
                            print("Successfully saved data.")
                            
                        }
                    }
                }
                
            }
            
            UserDefaults.standard.set(true, forKey: "profileSetUpComplete")
            
            self.performSegue(withIdentifier: "profileSetUpHomeSeg", sender: self)
        } else {
            
            let alert = UIAlertController(title: "Profile Incomplete!", message: "Please fill out everything before proceeding.", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Okay", style: .default)
            alert.addAction(okayAction)
            present(alert, animated: true, completion: nil)
        }
    }
    
   
    func uploadImageToFireStorage(picture: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = picture.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data."])))
            return
        }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imageFileName = "\(UUID().uuidString).jpg"
        let imageRef = storageRef.child("images/\(imageFileName)")
        
        let uploadTask = imageRef.putData(imageData, metadata: nil) { metadata, error in
            
            if let error = error {
                completion(.failure(error))
            } else {
                imageRef.downloadURL { url, error in
                    if let downloadURL = url {
                        completion(.success(downloadURL.absoluteString))
                    } else if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Failed to retrieve download URL"])))
                    }
                }
            }
            
        }
    }
    
}

extension ProfileSetUpViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let pickedImage = info[.originalImage] as? UIImage {
            
            profileImage.image = pickedImage
            uploadImageToFireStorage(picture: pickedImage) { result in
                
                switch result {
                    
                case .success(let urlString):
                    
                    self.imageString = urlString
                    
                case .failure(let error):
                    
                    print("Error uploading image: \(error.localizedDescription)")
                }
            }
        }
        picker.dismiss(animated: true, completion: nil)
        isImageChosen = true
        
    }
}

extension ProfileSetUpViewController: UINavigationControllerDelegate {
    
    
}

extension ProfileSetUpViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    
        nameTextField.endEditing(true)
        ageTextField.endEditing(true)
        return true
        
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        
        nameTextField.resignFirstResponder()
        nameTextField.endEditing(true)
        
        ageTextField.resignFirstResponder()
        ageTextField.endEditing(true)
    }

}
