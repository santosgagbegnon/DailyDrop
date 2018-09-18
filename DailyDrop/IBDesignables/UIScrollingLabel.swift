//
//  UIScrollingLabel.swift
//  Daily Drop
//
//  Created by Santos on 2018-x06-15.
//  Copyright © 2018 Santos. All rights reserved.
//

import UIKit

class UIScrollingLabel: UILabel {
    override var text: String? {
        didSet {
            if let newText = text {
                if newText.count > "Lil Moosey, Dc The Don".count {
                    UIView.animate(withDuration: 12, delay: 0, options: [.curveLinear], animations: {
                        self.center = CGPoint(x: CGFloat(self.superview!.frame.maxX + self.layer.bounds.width/2), y:self.center.y)
                    }, completion: { _ in
                        let bouncingAnimation = CABasicAnimation(keyPath: "position")
                        bouncingAnimation.fromValue = CGPoint(x:0-self.layer.bounds.width/2,y:self.center.y)
                        bouncingAnimation.toValue = CGPoint(x: CGFloat(self.superview!.frame.maxX + self.layer.bounds.width/2), y: self.center.y)
                        bouncingAnimation.duration = 18
                        bouncingAnimation.repeatCount = Float.infinity
                        self.layer.add(bouncingAnimation, forKey: "position")
                    })
                }
            }
        }
    }
    
    
}
