//
//  DistanceViewController.swift
//  BestLife
//
//  Created by Jake Gordon on 03/07/2023.
//

import UIKit

class DistanceViewController: UIViewController {

    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var distanceSlider: UISlider!
    
    var distanceChosen = 10000
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if UserDefaults.standard.value(forKey: "distancePreference") != nil {
           
            let userDistance = UserDefaults.standard.value(forKey: "distancePreference") as? Int ?? 10000
            let modifiedUserDistance = userDistance / 1000
            distanceLabel.text = "\(modifiedUserDistance)km"
            distanceSlider.value = Float(modifiedUserDistance) / 100
            let trackRect = distanceSlider.trackRect(forBounds: distanceSlider.frame)
                let thumbRect = distanceSlider.thumbRect(forBounds: distanceSlider.bounds, trackRect: trackRect, value: distanceSlider.value)
                self.distanceLabel.center = CGPoint(x: thumbRect.midX, y: self.distanceLabel.center.y)
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
        
        UserDefaults.standard.set(distanceChosen, forKey: "distancePreference")
        
        let confirmDistanceChange = UIAlertController(title: "Nice!", message: "Your distance preferences have been saved!", preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "OK", style: .default)
        confirmDistanceChange.addAction(okayAction)
        present(confirmDistanceChange, animated: true)

    }
    
    
 

}
