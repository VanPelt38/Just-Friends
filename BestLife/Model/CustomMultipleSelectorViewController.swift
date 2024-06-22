//
//  CustomMultipleSelectorViewController.swift
//  BestLife
//
//  Created by Jake Gordon on 18/06/2024.
//

import Foundation
import Eureka
import UIKit

class CustomMultipleSelectorViewController: MultipleSelectorViewController<GenericMultipleSelectorRow<String, PushSelectorCell<Set<String>>>> {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "arrow25"), style: .plain, target: self, action: #selector(popVC))
    }
    
    @objc func popVC() {
        navigationController?.popViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
                    cell.textLabel?.font = UIFont(name: "Gill Sans", size: 20)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
}
