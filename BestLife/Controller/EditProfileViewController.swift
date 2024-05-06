//
//  EditProfileViewController.swift
//  BestLife
//
//  Created by Jake Gordon on 06/05/2024.
//

import UIKit
import Eureka

class EditProfileViewController: FormViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        createProfileDetailsForm()
    }
    
    func createProfileDetailsForm() {
        
        tableView.backgroundColor = UIColor(red: 255/255, green: 204/255, blue: 204/255, alpha: 1.0)
        
        let section = Section()
        form +++ section
        
        section <<< TextRow() { row in
            row.title = "My Hometown:"
            row.cell.backgroundColor = UIColor(red: 255/255, green: 204/255, blue: 204/255, alpha: 1.0)
        }
        
        section <<< TextRow() { row in
            row.title = "My Profession:"
            row.cell.backgroundColor = UIColor(red: 255/255, green: 204/255, blue: 204/255, alpha: 1.0)
        }

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
//        section <<< LabelRow() { row in
//            
//            row.title = "My interests.."
//            row.cell.backgroundColor = UIColor(red: 255/255, green: 204/255, blue: 204/255, alpha: 1.0)
//            row.cell.height = { 35 }
//        }
//        section <<< TextAreaRow() { row in
//            row.placeholder = ""
//            row.cell.backgroundColor = UIColor(red: 255/255, green: 204/255, blue: 204/255, alpha: 1.0)
//            row.cell.textView.backgroundColor = .white
//            row.cell.textView.layer.cornerRadius = 10
//        }
        
        let interestsSelectrow = MultipleSelectorRow<String>() { row in
            row.title = "My Interests:"
            row.cell.backgroundColor = UIColor(red: 255/255, green: 204/255, blue: 204/255, alpha: 1.0)
            row.options = ["Sports", "Exercise", "Reading", "Foodie", "Nightlife", "Gardening", "Socialising", "Music", "Gaming", "Cinema"]
        }
        section <<< interestsSelectrow
        
        var selectedOptions: Set<String> = []
        interestsSelectrow.onChange { [weak self] row in
            if row.value?.count ?? 0 > 5 {
                // Display an alert if the maximum number of selections is exceeded
                let alertController = UIAlertController(title: "Uh-oh", message: "You can only select up to 5 interests.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alertController, animated: true, completion: nil)
            } else {
                selectedOptions = Set(row.value ?? [])
            }
        }
        
        section <<< ButtonRow() { row in
            row.cell.backgroundColor = UIColor(red: 255/255, green: 204/255, blue: 204/255, alpha: 1.0)
            row.title = "Save My Profile"
        }

    }
}
