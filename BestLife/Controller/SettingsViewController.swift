//
//  SettingsViewController.swift
//  BestLife
//
//  Created by Jake Gordon on 03/07/2023.
//

import UIKit

class SettingsViewController: UIViewController {
    
    
    @IBOutlet weak var settingsTableView: UITableView!
    
    var settingTitles = ["Distance Preferences", "Delete Account"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settingsTableView.dataSource = self
        settingsTableView.delegate = self

      
    }

}

extension SettingsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return settingTitles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = settingTitles[indexPath.row]
        let disclosureIndicatorImage = UIImageView(image: UIImage(systemName: "chevron.right"))
        
        cell.contentConfiguration = content
       
        
        if indexPath.row == 0 {

            cell.accessoryView = disclosureIndicatorImage
        }

        
        return cell
    }
    
    
    
}

extension SettingsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == 0 {
            
            performSegue(withIdentifier: "settingsDistanceSeg", sender: self)
        }
    
    }
    
}
