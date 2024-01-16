//
//  MatchProfileViewController.swift
//  BestLife
//
//  Created by Jake Gordon on 08/07/2023.
//

import UIKit
import Kingfisher

class MatchProfileViewController: UIViewController {
    
    @IBOutlet weak var matchProfilePicture: UIImageView!
    @IBOutlet weak var profileDetails: UILabel!
    @IBOutlet weak var genderImage: UIImageView!
    @IBOutlet weak var profileDetailsStack: UIStackView!
    
    var matchProfile = ProfileModel()
    var profileDetailsArray: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpUI()
        setupProfile()
    }
    
    @objc func popVC() {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        profilePicSize()
    }
    
    func profilePicSize() {
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            
            let size = CGSize(width: self.view.frame.width / 3, height: self.view.frame.width / 3)
            matchProfilePicture.frame.size = size
            matchProfilePicture.frame.origin.x = (self.view.frame.width / 2) - matchProfilePicture.frame.size.width / 2
            matchProfilePicture.frame.origin.y = (self.view.frame.height / 2) - matchProfilePicture.frame.size.height / 2
            matchProfilePicture.clipsToBounds = true
            matchProfilePicture.layer.cornerRadius = matchProfilePicture.frame.size.width / 2
            
            let constraint = NSLayoutConstraint(item: profileDetailsStack, attribute: .top, relatedBy: .equal, toItem: matchProfilePicture, attribute: .bottom, multiplier: 1.0, constant: 37.0)
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
            matchProfilePicture.frame.size = size
            matchProfilePicture.frame.origin.y = 0
            matchProfilePicture.frame.origin.x = 0
            let constraint = NSLayoutConstraint(item: profileDetailsStack, attribute: .top, relatedBy: .equal, toItem: matchProfilePicture, attribute: .bottom, multiplier: 1.0, constant: 37.0)
            let constraint2 = NSLayoutConstraint(item: profileDetailsStack, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1.0, constant: 30.0)
                        self.view.addConstraint(constraint)
                        self.view.addConstraint(constraint2)
        }
    }
    
    func setUpUI() {
        
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "arrow25"), style: .plain, target: self, action: #selector(popVC))
//        let size = CGSize(width: self.view.frame.width, height: self.view.frame.width)
//        matchProfilePicture.frame.size = size
//        matchProfilePicture.frame.origin.y = 0
        profilePicSize()
    }
    
    func setupProfile() {
        
        profileDetailsArray.append(matchProfile.name)
        profileDetailsArray.append(String(matchProfile.age))
        profileDetailsArray.append(matchProfile.gender)
        
        DispatchQueue.main.async { [self] in
            
            self.navigationItem.title = self.profileDetailsArray[0]
            self.profileDetails.text = "\(profileDetailsArray[0]), \(profileDetailsArray[1])"
            self.genderImage.image = (self.profileDetailsArray[2] == "male") ? UIImage(named: "big male") : UIImage(named: "big female")
            
            if let url = URL(string: matchProfile.picture) {
                
                do {
                    
                   self.matchProfilePicture.kf.setImage(with: url)

                } catch {
                    
                    print("ERROR LOADING PROFILE IMAGE: \(error.localizedDescription)")
                }
            }
        }
    }
  
}


