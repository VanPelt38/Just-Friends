//
//  DatePlanCell.swift
//  BestLife
//
//  Created by Jake Gordon on 07/05/2023.
//

import UIKit

protocol CustomTableViewCellDelegate: AnyObject {
    
    func customTableViewCellDidTapButton(_ cell: DatePlanCell, indexPath: IndexPath, buttonName: String) async
}


class DatePlanCell: UITableViewCell {
    
    weak var delegate: CustomTableViewCellDelegate?
    var indexPath: IndexPath?
    
    @IBOutlet weak var profilePicture: UIImageView!
    
    @IBOutlet weak var datePlanLabel: UILabel!
    
    @IBOutlet weak var ageLabel: UILabel!
    
    @IBOutlet weak var genderLabel: UIImageView!
    
    @IBOutlet weak var acceptedButton: UIButton!
    
    @IBOutlet weak var rejectedButton: UIButton!
    
    @IBAction func acceptedPressed(_ sender: UIButton) {
        
        if let indexPath = indexPath {
            Task.init {
                await delegate?.customTableViewCellDidTapButton(self, indexPath: indexPath, buttonName: "acceptedButton")
            }
        }
    }
    
    @IBAction func rejectedPressed(_ sender: UIButton) {
        
        if let indexPath = indexPath {
            Task.init {
                await delegate?.customTableViewCellDidTapButton(self, indexPath: indexPath, buttonName: "rejectedButton")
            }
        }
        
    }
    
    @IBOutlet weak var viewProfileButton: UIButton!
    
    @IBAction func viewProfilePressed(_ sender: UIButton) {

        if let indexPath = indexPath {
            Task.init {
                await delegate?.customTableViewCellDidTapButton(self, indexPath: indexPath, buttonName: "viewProfileButton")
            }
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
       
        viewProfileButton.clipsToBounds = true
        viewProfileButton.layer.cornerRadius = viewProfileButton.frame.size.width / 2
        viewProfileButton.tintColor = .black
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
