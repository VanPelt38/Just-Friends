//
//  Toast.swift
//  BestLife
//
//  Created by Jake Gordon on 23/10/2024.
//

import Foundation
import UIKit

extension UIViewController {
    
    func showToast(message: String, duration: Double = 3.0) {
        
        let toastLabel = UILabel(frame: CGRect(x: Int((self.view.frame.size.width - (self.view.frame.size.width - 100)) / 2), y:
                                                Int(self.view.frame.size.height) - 250, width: Int(self.view.frame.size.width) - 100, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont(name: "Gill Sans", size: 14)!
        toastLabel.text = message
        toastLabel.alpha = 0.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        
        self.view.addSubview(toastLabel)
        
        UIView.animate(withDuration: 0.5, animations: {
            toastLabel.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.5, delay: duration, options: .curveEaseIn, animations: {
                toastLabel.alpha = 0.0
            }) { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }
}
