//
//  MusicOptionsPopUpViewController.swift
//  Daily Drop
//
//  Created by Santos on 2018-06-17.
//  Copyright © 2018 Santos. All rights reserved.
//

import Foundation
import UIKit


class MusicFeaturesVC : UIViewController {
    @IBOutlet weak var optionsView: UIRoundableView!
    @IBOutlet weak var secondOption: UICustomButton!
    weak var passDataProtocol : PassPopUpData?
    var isTimedOutDisplay = false
    override func viewDidLoad() {
        super.viewDidLoad()
        optionsView.center.y = optionsView.layer.bounds.height/2 + optionsView.superview!.layer.bounds.height
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
        if isTimedOutDisplay {
            secondOption.setTitle("Next Track", for: .normal)
        }

    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.3, animations: {
            self.optionsView.center.y = self.optionsView.layer.bounds.height/2 + self.optionsView.superview!.layer.bounds.height
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
        }) { (true) in
            self.dismiss(animated: false)
        }
    }
    
    @IBAction func optionButtonPressed(_ sender: UIButton) {
        print(sender.tag)
        UIView.animate(withDuration: 0.3, animations: {
            self.optionsView.center.y = self.optionsView.layer.bounds.height/2 + self.optionsView.superview!.layer.bounds.height
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
            
        }) { (true) in
            if sender.tag == 0 {
                self.passDataProtocol?.playWholeTrack()
                self.dismiss(animated: false)
            }
            else if sender.tag == 1 {
                if self.isTimedOutDisplay {
                    self.passDataProtocol?.goToNextTrack()
                }
                else {
                    self.passDataProtocol?.skipAlbum()
                }
                self.dismiss(animated: false)

               
            }
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        UIView.animate(withDuration: 0.3, animations: {
            self.optionsView.center.y = 510
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            })
    }
    

}

