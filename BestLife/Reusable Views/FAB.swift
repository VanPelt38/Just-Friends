//
//  FAB.swift
//  BestLife
//
//  Created by Jake Gordon on 27/10/2024.
//

import Foundation
import UIKit

class FAB: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    private func setupButton() {
        
        self.backgroundColor = UIColor(red: 0.075, green: 0, blue: 0.557, alpha: 1.0)
        self.tintColor = .white
        self.layer.cornerRadius = 30
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.3
        self.layer.shadowOffset = CGSize(width: 2, height: 2)
        self.layer.shadowRadius = 4
        self.setImage(UIImage(systemName: "envelope.fill"), for: .normal)
        self.imageView?.contentMode = .scaleAspectFit
    }
}
