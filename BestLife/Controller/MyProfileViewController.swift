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
import Eureka

class MyProfileViewController: FormViewController {
    
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var cameraImage: UIButton!
    
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
        createProfileDetailsForm()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if newPicHasBeenChosen {
            if let safeImage = profilePicture.image {
                
                let realmImage = convertImageToData(image: safeImage)
                if realmImage.count < 16000000 {
                    if imageExtension != "unsupported" {
                        persistPictureLocally(realmPicture: realmImage)
                        
                        Task.init {
                            imageString = await uploadImageToFireStorage(picture: safeImage)
                            await saveImageToFireStore(imageURL: imageString ?? "none")
                        }
                    } else {
                        let badImageAlert = UIAlertController(title: "Uh-oh", message: "We're sorry but the image file you chose was unsupported - please try again with the following extensions: heic, jpeg, jpg, png.", preferredStyle: .alert)
                        let okayAction = UIAlertAction(title: "Okay", style: .default)
                        badImageAlert.addAction(okayAction)
                        present(badImageAlert, animated: true, completion: nil)
                    }
                } else {
                    let imageTooBigAlert = UIAlertController(title: "Uh-oh", message: "The image you chose was too big and could not be saved - please try again with a file size under 16Mb.", preferredStyle: .alert)
                    let okayAction = UIAlertAction(title: "Okay", style: .default)
                    imageTooBigAlert.addAction(okayAction)
                    self.present(imageTooBigAlert, animated: true, completion: nil)
                }
            }
        }
    }
    
    @objc func popVC() {
        navigationController?.popViewController(animated: true)
    }
    
    func createProfileDetailsForm() {
        
        tableView.contentInset = UIEdgeInsets(top: -20, left: 0, bottom: 0, right: 0)
        tableView.separatorStyle = .none
        let section = Section("Hi there")
        form +++ section
        let headerView = UIView(frame: CGRect(x: tableView.bounds.origin.x, y: tableView.bounds.origin.y, width: tableView.bounds.width, height: 44))
        let curvePath = UIBezierPath(roundedRect: headerView.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 10, height: 10))
        let curveLayer = CAShapeLayer()
        curveLayer.path = curvePath.cgPath
        headerView.layer.mask = curveLayer
        let titleLabel = UILabel(frame: CGRect(x: headerView.bounds.origin.x, y: headerView.bounds.origin.y, width: headerView.bounds.width, height: 44))
        headerView.backgroundColor = UIColor(red: 255/255, green: 204/255, blue: 204/255, alpha: 1.0)
        titleLabel.text = "\(profileDetailsArray[0]) \(profileDetailsArray[1])"
        titleLabel.textAlignment = .center // Set the alignment here
        let separator = UIView()
        separator.backgroundColor = .lightGray
        separator.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(separator)
        separator.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 8).isActive = true
        separator.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -8).isActive = true
        separator.bottomAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
                separator.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        headerView.addSubview(titleLabel)
        
        // Assign the custom view to the section header
        let head = HeaderFooterView<UIView>(.callback({
            return headerView
        }))
        section.header = head
        section <<< LabelRow() { row in
            row.title = "A bit about me.."
            row.cell.height = { 35 }
            row.cell.backgroundColor = UIColor(red: 255/255, green: 204/255, blue: 204/255, alpha: 1.0)
        }
        section <<< TextAreaRow() { row in
            row.placeholder = ""
            row.cell.backgroundColor = UIColor(red: 255/255, green: 204/255, blue: 204/255, alpha: 1.0)
            row.cell.textView.backgroundColor = .white
            row.cell.textView.layer.cornerRadius = 10
            row.cell.textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        }
        section <<< LabelRow() { row in
            
            row.title = "My interests.."
            row.cell.backgroundColor = UIColor(red: 255/255, green: 204/255, blue: 204/255, alpha: 1.0)
            row.cell.height = { 35 }
        }
        section <<< TextAreaRow() { row in
            row.placeholder = ""
            row.cell.backgroundColor = UIColor(red: 255/255, green: 204/255, blue: 204/255, alpha: 1.0)
            row.cell.textView.backgroundColor = .white
            row.cell.textView.layer.cornerRadius = 10
        }

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
            
//            let constraint = NSLayoutConstraint(item: profileDetailsStack, attribute: .top, relatedBy: .equal, toItem: cameraImage, attribute: .bottom, multiplier: 1.0, constant: 10.0)
//            self.view.addConstraint(constraint)
//            
// 
//            let centerXConstraint = NSLayoutConstraint(item: profileDetailsStack,
//                                                       attribute: .centerX,
//                                                       relatedBy: .equal,
//                                                       toItem: view,
//                                                       attribute: .centerX,
//                                                       multiplier: 1.0,
//                                                       constant: 0.0)

 

            // Add constraints to the superview
            
//            view.addConstraints([centerXConstraint, constraint])
            
        } else {
            
            let size = CGSize(width: self.view.frame.width, height: self.view.frame.width)
            profilePicture.frame.size = size
            profilePicture.frame.origin.y = 0
            profilePicture.frame.origin.x = 0
//            let constraint = NSLayoutConstraint(item: profileDetailsStack, attribute: .top, relatedBy: .equal, toItem: cameraImage, attribute: .bottom, multiplier: 1.0, constant: -10.0)
//            let constraint2 = NSLayoutConstraint(item: profileDetailsStack, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1.0, constant: 30.0)
//                        self.view.addConstraint(constraint)
//                        self.view.addConstraint(constraint2)
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
//                    self.profileDetails.text = "\(profileDetailsArray[0]), \(profileDetailsArray[1])"
//                    self.genderImage.image = (self.profileDetailsArray[2] == "male") ? UIImage(named: "big male") : UIImage(named: "big female")
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

            if convertImageToData(image: pickedImage).count < 16000000 {

                newPicHasBeenChosen = true
                profilePicture.image = pickedImage
                
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
            } else {
                let imageTooBigAlert = UIAlertController(title: "Uh-oh", message: "The image you've chosen is too big - please pick one with a file size under 16Mb.", preferredStyle: .alert)
                let okayAction = UIAlertAction(title: "Okay", style: .default)
                imageTooBigAlert.addAction(okayAction)
                picker.dismiss(animated: true, completion: {
                    self.present(imageTooBigAlert, animated: true, completion: nil)
                })
            }
        } else {
            picker.dismiss(animated: true, completion: nil)
        }
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

