//
//  DistanceViewController.swift
//  BestLife
//
//  Created by Jake Gordon on 03/07/2023.
//

import UIKit

class DistanceViewController: BaseViewController {

    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var distanceSlider: UISlider!
    @IBOutlet weak var updateButton: UIButton!
    
    var distanceChosen: Int? = nil
    var firstViewLoad = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "arrow25"), style: .plain, target: self, action: #selector(popVC))
        updateButton.layer.cornerRadius = updateButton.frame.height / 2

        if UserDefaults.standard.value(forKey: "distancePreference") != nil {
           
            let userDistance = UserDefaults.standard.value(forKey: "distancePreference") as? Int ?? 10000
            let modifiedUserDistance = userDistance / 1000
            distanceLabel.text = "\(modifiedUserDistance)km"
            distanceSlider.value = Float(modifiedUserDistance) / 100
                    }
      
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation
        let currentDevice = UIDevice.current.userInterfaceIdiom
        
        if currentDevice == .pad {

            switch orientation {
            case .landscapeLeft, .landscapeRight:
                
                let trackRect = distanceSlider.trackRect(forBounds: distanceSlider.frame)
                    let thumbRect = distanceSlider.thumbRect(forBounds: distanceSlider.bounds, trackRect: trackRect, value: distanceSlider.value)
                if firstViewLoad {
                  
                    self.distanceLabel.center = CGPoint(x: thumbRect.midX, y: self.distanceLabel.center.y + 15)
                } else {
                    self.distanceLabel.center = CGPoint(x: thumbRect.midX, y: self.distanceLabel.center.y)
                   
                }
                
            case .portrait, .portraitUpsideDown:
                
                let trackRect = distanceSlider.trackRect(forBounds: distanceSlider.frame)
                    let thumbRect = distanceSlider.thumbRect(forBounds: distanceSlider.bounds, trackRect: trackRect, value: distanceSlider.value)
                if !firstViewLoad {
                    self.distanceLabel.center = CGPoint(x: thumbRect.midX, y: self.distanceLabel.center.y)
                   
                } else {
                
                    self.distanceLabel.center = CGPoint(x: thumbRect.midX, y: self.distanceLabel.center.y + 200)
                }
                
            default:
                break
            }

        } else {
            
            let trackRect = distanceSlider.trackRect(forBounds: distanceSlider.frame)
                let thumbRect = distanceSlider.thumbRect(forBounds: distanceSlider.bounds, trackRect: trackRect, value: distanceSlider.value)
                self.distanceLabel.center = CGPoint(x: thumbRect.midX, y: self.distanceLabel.center.y + 10)
        }
        firstViewLoad = false
    }

    
    @objc func popVC() {
        navigationController?.popViewController(animated: true)
    }
    
    func dismissViewAfterUpdate() {
        if let navCont = navigationController {
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                let confirmDistanceChange = UIAlertController(title: "Nice", message: "Your distance preferences have been saved.", preferredStyle: .alert)
                let okayAction = UIAlertAction(title: "Okay", style: .default)
                confirmDistanceChange.addAction(okayAction)
                self.present(confirmDistanceChange, animated: true)
            }
            navigationController?.popViewController(animated: true)
            CATransaction.commit()
        }
    }

    @IBAction func distanceChanged(_ sender: UISlider) {
        
        let distance = sender.value * 100
        let roundedDistance = distance.rounded()
        let userNumber = Int(roundedDistance)
        self.distanceLabel.text = "\(userNumber)km"
        self.distanceChosen = userNumber * 1000
        
        let trackRect = sender.trackRect(forBounds: sender.frame)
            let thumbRect = sender.thumbRect(forBounds: sender.bounds, trackRect: trackRect, value: sender.value)
            self.distanceLabel.center = CGPoint(x: thumbRect.midX, y: self.distanceLabel.center.y)
    }
    
    @IBAction func updateDistancePressed(_ sender: UIButton) {
        if let distanceChosen {
            UserDefaults.standard.set(distanceChosen, forKey: "distancePreference")
        }
        dismissViewAfterUpdate()
    }
}
