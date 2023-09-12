//
//  MatchProfileViewController.swift
//  BestLife
//
//  Created by Jake Gordon on 08/07/2023.
//

import UIKit
import Kingfisher

class MatchProfileViewController: UIViewController {
    
    @IBOutlet weak var matchProfileTableView: UITableView!
    @IBOutlet weak var matchProfilePicture: UIImageView!
    
    var matchProfile = ProfileModel()
    var profileDetailsArray: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupProfile()
        
        matchProfileTableView.dataSource = self
        matchProfileTableView.delegate = self
        matchProfileTableView.backgroundColor = .clear
        matchProfileTableView.backgroundView = nil
    }
    
    func setupProfile() {
        
        profileDetailsArray.append(matchProfile.name)
        profileDetailsArray.append(String(matchProfile.age))
        profileDetailsArray.append(matchProfile.gender)
        
        DispatchQueue.main.async { [self] in
            
           
            
            if let url = URL(string: matchProfile.picture) {
                
                do {
                    
                   self.matchProfilePicture.kf.setImage(with: url)

                } catch {
                    
                    print("ERROR LOADING PROFILE IMAGE: \(error.localizedDescription)")
                }
            }
            self.matchProfileTableView.reloadData()
        }
        self.matchProfileTableView.reloadData()
    }
  
}

extension MatchProfileViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if profileDetailsArray.count == 0 {
            
            return 1
        } else {
            
            return profileDetailsArray.count * 2
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "matchProfileCell", for: indexPath)
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

extension MatchProfileViewController: UITableViewDelegate {
    
    
}
