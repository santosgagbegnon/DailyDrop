//
//  IntialLoginInViewController.swift
//  Daily Drop
//
//  Created by Santos on 2018-06-04.
//  Copyright © 2018 Santos. All rights reserved.
//

import UIKit

class InitialLoginVC: UIViewController {
    @IBOutlet weak var backgroundAlbumArt: UIImageView!
    @IBOutlet weak var foregroundAlbumArt: UIImageView!
    @IBOutlet weak var musicNameLabel: UILabel!
    private var imageOne = UIImage(named: "NavReckless.jpg")
    private var imageTwo = UIImage(named: "imupset.jpg")
    private var imageThree = UIImage(named: "watch.jpg")
    private var imageFour = UIImage(named: "testingasap.jpeg")

    lazy var imageInformation = [(name:"Reckless - Nav", image:imageOne),(name:"I'm Upset - Drake", image: imageTwo),(name:"Watch - Travis Scott", image: imageThree), (name:"Testing - A$AP Rocky", image: imageFour)]
    private var currentIndex = 0
    static var spotifySession: AnyObject?
    private var timer : Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        foregroundAlbumArt.image = imageOne
        backgroundAlbumArt.image = imageOne
        musicNameLabel.text = imageInformation[0].name
        timer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(imageRefresh), userInfo: nil, repeats: true)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    @objc func imageRefresh(){
        if currentIndex == imageInformation.count - 1 {
            currentIndex = 0
        }
        else {
            currentIndex += 1
        }
        //Update Label
        UIView.transition(with: self.musicNameLabel, duration: 2.0, options: [.transitionCrossDissolve] , animations: { [weak self] in
            guard let `self` = self else { return }
            self.musicNameLabel.text = self.imageInformation[self.currentIndex].name
            
            }, completion: nil)
        
        //Update foreground Album
        UIView.transition(with: self.foregroundAlbumArt, duration: 2.0, options: [.transitionCrossDissolve] , animations: { [weak self] in
            guard let `self` = self else { return }
            self.foregroundAlbumArt.image = self.imageInformation[self.currentIndex].image
            }, completion: nil)
        //Update background Album
        
        UIView.transition(with: self.backgroundAlbumArt, duration: 2.0, options: [.transitionCrossDissolve] , animations: { [weak self] in
            guard let `self` = self else { return }
            self.backgroundAlbumArt.image = self.imageInformation[self.currentIndex].image
            }, completion: nil)
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        self.timer.invalidate()
    }
    
}

