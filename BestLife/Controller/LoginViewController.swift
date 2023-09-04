//
//  LoginViewController.swift
//  BestLife
//
//  Created by Jake Gordon on 15/12/2022.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    
    private let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        setupButtons()
        setUpViewColour()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)

    }
    
    func setUpViewColour() {
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.bounds
        gradientLayer.colors = [UIColor(red: 0.075, green: 0, blue: 0.557, alpha: 1).cgColor, UIColor(red: 0.510, green: 0.482, blue: 1, alpha: 1).cgColor]
        self.view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func setupButtons() {

        signInButton.layer.cornerRadius = signInButton.frame.height / 2
        signUpButton.layer.cornerRadius = signUpButton.frame.height / 2
    }
    
    @IBAction func loginButton(_ sender: UIButton) {
        
        if let email = emailTextField.text, let password = passwordTextField.text {
            Task.init {
            await login(email: email, password: password)
                  }
        } else {
            let enterValidDetailsAlert = UIAlertController(title: "", message: "Please enter a valid email and password.", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Okay", style: .default)
            enterValidDetailsAlert.addAction(okayAction)
            self.present(enterValidDetailsAlert, animated: true)
        }
        
    }
    
    @IBAction func registerButton(_ sender: Any) {
        
        if let email = emailTextField.text, let password = passwordTextField.text {
            
            Auth.auth().createUser(withEmail: email, password: password) { [self]
                authResult, error in
                
                if let e = error {
                    DispatchQueue.main.async { [self] in
                        showAlert(title: "Uh Oh", message: "There was an error registering: \(e.localizedDescription)")
                    }
                } else {
                    Task.init {
                        await login(email: email, password: password)
                    }
                }
            }
        } else {
            
            let enterValidDetailsAlert = UIAlertController(title: "", message: "Please enter a valid email and password.", preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Okay", style: .default)
            enterValidDetailsAlert.addAction(okayAction)
            self.present(enterValidDetailsAlert, animated: true)
        }
        
    }
    
    func showAlert(title: String, message: String) {
        
        let enterValidDetailsAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Okay", style: .default)
        enterValidDetailsAlert.addAction(okayAction)
        self.present(enterValidDetailsAlert, animated: true)
    }
    
    func login(email: String, password: String) async {
        
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
                    
                    let userID = Auth.auth().currentUser?.uid
                    
                    if let safeID = userID {
                        
                        let userCollection = self.db.collection("users").document(safeID).collection("registration").document(safeID)
                        do {
                           let userDocument = try await userCollection.getDocument()
                            if userDocument.exists {
                                let data = userDocument.data()
                                if let safeData = data {
                                    if safeData["profileSetUp"] as? Bool ?? false {
                                        performSegue(withIdentifier: "loginHomeSeg", sender: self)
                                    } else {
                                        performSegue(withIdentifier: "loginProfileSeg", sender: self)
                                    }
                                }
                            } else {
                                let userRegistrationID = self.db.collection("users").document(safeID).collection("registration").document(safeID)
                                do {
                                    try await userRegistrationID.setData([
                                        "userID": safeID,
                                        "profileSetUp": false
                                    ])
                                    performSegue(withIdentifier: "loginProfileSeg", sender: self)
                                } catch {
                                    print("error setting userID")
                                }
                            }
                        } catch {
                            print("error getting document: \(error)")
                        }
                    }
        } catch {
            DispatchQueue.main.async {
                self.showAlert(title: "Uh Oh", message: "There was an error signing in: \(error.localizedDescription)")
            }
        }
    }
    
}

extension LoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    
        emailTextField.endEditing(true)
        passwordTextField.endEditing(true)
        return true
        
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        
        emailTextField.resignFirstResponder()
        passwordTextField.endEditing(true)
        
        emailTextField.resignFirstResponder()
        passwordTextField.endEditing(true)
    }

}
