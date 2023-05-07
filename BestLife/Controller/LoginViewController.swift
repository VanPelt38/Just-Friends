//
//  LoginViewController.swift
//  BestLife
//
//  Created by Jake Gordon on 15/12/2022.
//

import UIKit
import Firebase
import FirebaseAuth

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        emailTextField.delegate = self
        passwordTextField.delegate = self

    }
  
    @IBAction func loginButton(_ sender: UIButton) {
        
        if let email = emailTextField.text, let password = passwordTextField.text {
            
            Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
              guard let strongSelf = self else { return }
              
                if let e = error {
                    print(e)
                } else {
                    
                    if UserDefaults.standard.bool(forKey: "profileSetUpComplete") != true {
                        
                        strongSelf.performSegue(withIdentifier: "loginProfileSeg", sender: self)
                    } else {
                        
                        strongSelf.performSegue(withIdentifier: "loginHomeSeg", sender: self)
                    }
                }
                
            }
            
        }
        
    }
    
    @IBAction func registerButton(_ sender: Any) {
        
        if let email = emailTextField.text, let password = passwordTextField.text {
            
            Auth.auth().createUser(withEmail: email, password: password) {
                authResult, error in
                
                if let e = error {
                    
                    print(e)
                } else {
                    
                    let savedAlert = UIAlertController(title: "Success!", message: "Your Details Have Been Registered.", preferredStyle: .alert)
                    let okayAction = UIAlertAction(title: "Okay", style: .default)
                    savedAlert.addAction(okayAction)
                    self.present(savedAlert, animated: true, completion: nil)
                    
                    if UserDefaults.standard.bool(forKey: "profileSetUpComplete") != true {
                        
                        self.performSegue(withIdentifier: "loginProfileSeg", sender: self)
                    } else {
                        
                        self.performSegue(withIdentifier: "loginHomeSeg", sender: self)
                    }
                    
                    
                }
            }
        }
        
    }
    
}

extension LoginViewController: UITextFieldDelegate {
    
    
}
