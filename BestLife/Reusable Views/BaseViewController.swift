//
//  BaseViewController.swift
//  BestLife
//
//  Created by Jake Gordon on 27/10/2024.
//

import UIKit
import MessageUI
import FirebaseAuth

class BaseViewController: UIViewController {
    
    let fab = FAB()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupFAB()
       
    }
    
    private func setupFAB() {
        
        fab.frame = CGRect(x: self.view.frame.width - 80, y: self.view.frame.height - 100, width: 60, height: 60)
        fab.addTarget(self, action: #selector(fabTapped), for: .touchUpInside)
        fab.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(fab)
        
        NSLayoutConstraint.activate([
            fab.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            fab.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            fab.widthAnchor.constraint(equalToConstant: 60),
            fab.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    @objc private func fabTapped() {
        sendEmailToDevelopers()
    }
    
    func sendEmailToDevelopers() {
        if MFMailComposeViewController.canSendMail() {
            
            let userID = Auth.auth().currentUser?.uid ?? "ID not found"
            let mailComposeVC = MFMailComposeViewController()
            mailComposeVC.mailComposeDelegate = self
            mailComposeVC.setToRecipients(["justfriendshelpdesk@gmail.com"])
            mailComposeVC.setSubject("Just Friends Support Issue")
            mailComposeVC.setMessageBody(
                "User ID: \(userID), Email: \(UserDefaults.standard.value(forKey: "email") ?? "Email not found"), Version: \(UIDevice.current.systemVersion)"
                , isHTML: false)
            present(mailComposeVC, animated: true, completion: nil)
        } else {
            self.showAlert(title: "Uh-oh", message: "Looks like your device doesn't have email configured. Please set it up and try again. You can also email us directly at justfriendshelpdesk@gmail.com .")
        }
    }
    
    func showAlert(title: String, message: String) {
        
        let enterValidDetailsAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Okay", style: .default)
        enterValidDetailsAlert.addAction(okayAction)
        self.present(enterValidDetailsAlert, animated: true)
    }
}

extension BaseViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: (any Error)?) {
        
        switch result {
        case .saved:
            self.showToast(message: "Your draft has been saved!")
        case .sent:
            self.showToast(message: "Your message has been sent!")
        default:
            print("nutting")
        }
        
        controller.dismiss(animated: true)
    }
}


