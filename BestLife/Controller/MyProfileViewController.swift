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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        myProfileTableView.delegate = self
        myProfileTableView.dataSource = self
        myProfileTableView.backgroundColor = .clear
        myProfileTableView.backgroundView = nil
        loadProfile()
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
        
        let currentCollection = db.collection("users").document(firebaseID!).collection("profile")
        let query = currentCollection.whereField("userID", isEqualTo: firebaseID)
        
        query.getDocuments { querySnapshot, error in
            
            self.profileDetailsArray = []
            
            if let e = error {
                print("There was an issue retrieving data from Firestore: \(e)")
            } else {
                
                if let snapshotDocuments = querySnapshot?.documents {
                    
                    for doc in snapshotDocuments {
                        
                        let data = doc.data()
                        if let age = data["age"] as? String, let gender = data["gender"] as? String, let name = data["name"] as? String, let picture = data["picture"] as? String, let userID = data["userID"] as? String {
                          
                            self.profileDetailsArray.append(name)
                            self.profileDetailsArray.append(age)
                            self.profileDetailsArray.append(gender)
    
                        
                            DispatchQueue.main.async {
                                
                               
                                
                                if let url = URL(string: picture) {
                                    
                                    do {
                                        
                                        self.profilePicture.kf.setImage(with: url)
                                        
                                        
//                                        let data = try Data(contentsOf: url)
//                                        let image = UIImage(data: data)
//                                        self.profilePicture.image = image
                                    } catch {
                                        
                                        print("ERROR LOADING PROFILE IMAGE: \(error.localizedDescription)")
                                    }
                                }
                                self.myProfileTableView.reloadData()
                            }
                            
                        }
                    }
                }
            }
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
            
            profilePicture.image = pickedImage
            uploadImageToFireStorage(picture: pickedImage) { result in
                
                switch result {
                    
                case .success(let urlString):
                    
                    self.imageString = urlString
                    
                    DispatchQueue.main.async { [self] in

                           
                        db.collection("users").document(firebaseID!).collection("profile").document("profile").updateData([
                                "picture": self.imageString
                            ]) { (error) in
                                
                                if let e = error {
                                    print("There was an issue saving data to firestore, \(e)")
                                } else {
                                    
                                    print("Successfully saved data.")
                                    
                                }
                            }
                        
                        
                    }

                    
                case .failure(let error):
                    
                    print("Error uploading image: \(error.localizedDescription)")
                }
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    
    func uploadImageToFireStorage(picture: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = picture.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data."])))
            return
        }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imageID = UserDefaults.standard.value(forKey: "profilePicRef")
        let imageFileName = "\(imageID).jpg"
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

extension MyProfileViewController: UINavigationControllerDelegate {
    
    
}

