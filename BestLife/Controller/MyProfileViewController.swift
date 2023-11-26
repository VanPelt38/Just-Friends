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
    
    @IBOutlet weak var myProfileTableView: UITableView!
    @IBOutlet weak var profilePicture: UIImageView!
    
    var profileDetailsArray: [String] = []
    var firebaseID: String?
    private let db = Firestore.firestore()
    var imageString: String?
    var imageExtension = ""
    var profilePicRef = ""
    var newPicHasBeenChosen = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        myProfileTableView.delegate = self
        myProfileTableView.dataSource = self
        myProfileTableView.backgroundColor = .clear
        myProfileTableView.backgroundView = nil
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
    
    func setUpUI() {
        
        let size = CGSize(width: self.view.frame.width, height: self.view.frame.width)
        profilePicture.frame.size = size
        profilePicture.frame.origin.y = 0
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
            
            DispatchQueue.main.async {
                
                if let safeImage = profile.picture {
                    let image = UIImage(data: safeImage)
                    self.title = self.profileDetailsArray[0]
                    self.profilePicture.image = image
                    self.myProfileTableView.reloadData()
                }
            }
        } else {
            print("profile couldn't be found.")
        }
        
    }
    
}

extension MyProfileViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if profileDetailsArray.count == 0 {
            
            return 1
        } else {
            
            return profileDetailsArray.count * 2
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "profileCell", for: indexPath)
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        
        if profileDetailsArray.count == 0 {
            
            cell.textLabel!.text = "Loading..."
            
        } else {
            
            switch indexPath.row {
                
            case 0:
                cell.textLabel!.text = "Name:"
            case 1:
                cell.textLabel!.text = profileDetailsArray[0]
            case 2:
                cell.textLabel!.text = "Age:"
            case 3:
                cell.textLabel!.text = profileDetailsArray[1]
            case 4:
                cell.textLabel!.text = "Gender:"
            case 5:
                cell.textLabel!.text = profileDetailsArray[2]
            default:
                cell.textLabel!.text = "Loading..."
            }
            
        }
        
        
        return cell
    }
    
    
    
}

extension MyProfileViewController: UITableViewDelegate {
    
    
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

