//
//  UIMusicCardView.swift
//  Daily Drop
//
//  Created by Santos on 2018-06-15.
//  Copyright © 2018 Santos. All rights reserved.
//

import UIKit

class UIMusicCardView: UIRoundableView {
    
    
    
    func touchAnimation() {
        self.transform = CGAffineTransform(scaleX: 0.975, y: 0.975)
        UIView.animate(withDuration: 0.7,delay: 0,usingSpringWithDamping: 0.5, initialSpringVelocity: 2, options:[],animations: {
            self.transform = CGAffineTransform.identity
            
        },completion: nil)
    }
    
}
