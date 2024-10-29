//
//  ContactViewController.swift
//  BestLife
//
//  Created by Jake Gordon on 23/12/2023.
//

import UIKit

class ContactViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "arrow25"), style: .plain, target: self, action: #selector(popVC))
    }

    @objc func popVC() {
        navigationController?.popViewController(animated: true)
    }
}
