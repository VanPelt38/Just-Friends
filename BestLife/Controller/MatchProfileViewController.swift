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
    
    func setUpUI() {
        
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "arrow25"), style: .plain, target: self, action: #selector(popVC))
        let size = CGSize(width: self.view.frame.width, height: self.view.frame.width)
        matchProfilePicture.frame.size = size
        matchProfilePicture.frame.origin.y = 0
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


