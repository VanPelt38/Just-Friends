//
//  ForgotPasswordViewController.swift
//  BestLife
//
//  Created by Jake Gordon on 09/04/2024.
//

import UIKit
import Firebase
import FirebaseAuth

class ForgotPasswordViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var sendLinkErrorMessage: UILabel!
    @IBOutlet weak var sendLinkButton: UIButton!
    
    var delegate: ForgotPasswordDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sendLinkButton.layer.cornerRadius = sendLinkButton.frame.height / 2
        sendLinkErrorMessage.isHidden = true
    }
    
    @IBAction func sendPasswordLink(_ sender: UIButton) {
        
        if let email = emailTextField.text {
            
            Auth.auth().sendPasswordReset(withEmail: email) { [self] error in
                
                if let e = error {
                    sendLinkErrorMessage.isHidden = false
                    sendLinkErrorMessage.text = e.localizedDescription
                    return
                }
                emailTextField.text = ""
                DispatchQueue.main.async {
                    self.dismiss(animated: true) {
                        self.delegate?.showSuccessAlert()
                    }
                }
            }
        }
    }
}
