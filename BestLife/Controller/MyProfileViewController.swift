//
//  MyProfileViewController.swift
//  BestLife
//
//  Created by Jake Gordon on 03/07/2023.
//

import UIKit
import Kingfisher
import FirebaseAuth
import FirebaseFirestore
import MobileCoreServices
import UniformTypeIdentifiers
import FirebaseStorage

class MyProfileViewController: UIViewController {
    
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var profileDetails: UILabel!
    @IBOutlet weak var cameraImage: UIButton!
    @IBOutlet weak var profileDetailsStack: UIStackView!
    @IBOutlet weak var genderImage: UIImageView!
    
    var profileDetailsArray: [String] = []
    var firebaseID: String?
    private let db = Firestore.firestore()
    var imageString: String?
    var imageExtension = ""
    var profilePicRef = ""
    var newPicHasBeenChosen = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpUI()
        loadProfile()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if newPicHasBeenChosen {
            if let safeImage = profilePicture.image {
                
                let realmImage = convertImageToData(image: safeImage)
                persistPictureLocally(realmPicture: realmImage)
                
                Task.init {
                    imageString = await uploadImageToFireStorage(picture: safeImage)
                    await saveImageToFireStore(imageURL: imageString ?? "none")
                }
            }
        }
    }
    
    @objc func popVC() {
        navigationController?.popViewController(animated: true)
    }
    
    func setUpUI() {
        
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "arrow25"), style: .plain, target: self, action: #selector(popVC))
        profilePicSize()
       cameraImage.clipsToBounds = true
        cameraImage.layer.cornerRadius = cameraImage.frame.size.width / 2
        
        let constraint = NSLayoutConstraint(item: cameraImage, attribute: .centerY, relatedBy: .equal, toItem: profilePicture, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        self.view.addConstraint(constraint)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        profilePicSize()
    }
    
    func profilePicSize() {
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            
            let size = CGSize(width: self.view.frame.width / 3, height: self.view.frame.width / 3)
            profilePicture.frame.size = size
            profilePicture.frame.origin.x = (self.view.frame.width / 2) - profilePicture.frame.size.width / 2
            profilePicture.frame.origin.y = (self.view.frame.height / 2) - profilePicture.frame.size.height / 2
            profilePicture.clipsToBounds = true
            profilePicture.layer.cornerRadius = profilePicture.frame.size.width / 2
            
            let constraint = NSLayoutConstraint(item: profileDetailsStack, attribute: .top, relatedBy: .equal, toItem: cameraImage, attribute: .bottom, multiplier: 1.0, constant: 10.0)
            self.view.addConstraint(constraint)
            
 
            let centerXConstraint = NSLayoutConstraint(item: profileDetailsStack,
                                                       attribute: .centerX,
                                                       relatedBy: .equal,
                                                       toItem: view,
                                                       attribute: .centerX,
                                                       multiplier: 1.0,
                                                       constant: 0.0)

 

            // Add constraints to the superview
            
            view.addConstraints([centerXConstraint, constraint])
            
        } else {
            
            let size = CGSize(width: self.view.frame.width, height: self.view.frame.width)
            profilePicture.frame.size = size
            profilePicture.frame.origin.y = 0
            profilePicture.frame.origin.x = 0
            let constraint = NSLayoutConstraint(item: profileDetailsStack, attribute: .top, relatedBy: .equal, toItem: cameraImage, attribute: .bottom, multiplier: 1.0, constant: -10.0)
            let constraint2 = NSLayoutConstraint(item: profileDetailsStack, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1.0, constant: 30.0)
                        self.view.addConstraint(constraint)
                        self.view.addConstraint(constraint2)
        }
    }
    
    func saveImageToFireStore(imageURL: String) async {
        
        if let currentUser = Auth.auth().currentUser {
            firebaseID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
        
        do {
            try await db.collection("users").document(firebaseID!).collection("profile").document("profile").updateData([
                "picture": imageURL
            ])
        } catch {
            print("There was an issue saving data to firestore, \(error)")
        }
    }
    
    func persistPictureLocally(realmPicture: Data) {
        
        if let currentUser = Auth.auth().currentUser {
            firebaseID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
        
        guard let realm = RealmManager.getRealm() else { return }
        if let profile = realm.objects(RProfile.self).filter("userID == %@", firebaseID).first {
            try! realm.write {
                profile.picture = realmPicture
            }
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

    
    @IBAction func newPhotoPressed(_ sender: UIButton) {
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.mediaTypes = [UTType.image.identifier]
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func loadProfile() {
        
        
        if let currentUser = Auth.auth().currentUser {
            firebaseID = currentUser.uid
        } else {
            print("no user is currently signed in")
        }
        
        self.profileDetailsArray = []
        
        guard let realm = RealmManager.getRealm() else {return}
        
        if let profile = realm.objects(RProfile.self).filter("userID == %@", firebaseID).first {
            
            self.profileDetailsArray.append(profile.name)
            self.profileDetailsArray.append(String(profile.age))
            self.profileDetailsArray.append(profile.gender)
            self.profilePicRef = profile.profilePicRef
            
            DispatchQueue.main.async { [self] in
                
                if let safeImage = profile.picture {
                    let image = UIImage(data: safeImage)
                    self.title = self.profileDetailsArray[0]
                    self.profilePicture.image = image
                    self.profileDetails.text = "\(profileDetailsArray[0]), \(profileDetailsArray[1])"
                    self.genderImage.image = (self.profileDetailsArray[2] == "male") ? UIImage(named: "big male") : UIImage(named: "big female")
                }
            }
        } else {
            print("profile couldn't be found.")
        }
        
    }
    
}


extension MyProfileViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let pickedImage = info[.originalImage] as? UIImage {
            newPicHasBeenChosen = true
            profilePicture.image = pickedImage
            
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
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    
    func uploadImageToFireStorage(picture: UIImage) async -> String {
        guard let imageData = picture.jpegData(compressionQuality: 0.8) else {
            return "Failed to convert image to data."
        }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imageFileName = profilePicRef
        let imageRef = storageRef.child("images/\(imageFileName)")
        
        do {
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            let uploadTask = try await imageRef.putDataAsync(imageData, metadata: metadata)
            let downloadURL = try await imageRef.downloadURL()
            return downloadURL.absoluteString
        } catch {
             return "failed to retrieve download url: \(error)"
        }
    }
}

extension MyProfileViewController: UINavigationControllerDelegate {
    
    
}

