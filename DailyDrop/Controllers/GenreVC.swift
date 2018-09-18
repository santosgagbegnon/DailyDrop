//
//  GenreVC.swift
//  Daily Drop
//
//  Created by Santos on 2018-08-23.
//  Copyright © 2018 Santos. All rights reserved.
//
import Firebase
import Foundation
import UIKit
class GenreVC : UIViewController, UICollectionViewDelegate, UICollectionViewDataSource{
    
    @IBOutlet weak var genreCollecionView: UICollectionView!
    private var genreInfo = [[String:String]]()
    private var genreImages = Array(repeating: UIImage(named: "PURPP.png")!, count: 14) //Test image
    private var currentCategory = [String:String]()
    override func viewDidLoad() {
        self.genreCollecionView.allowsMultipleSelection = false
        self.genreCollecionView.allowsSelection = true
        let ref = Database.database().reference().child("server").child("genres")
        let userDefaults = UserDefaults.standard
        ref.observeSingleEvent(of:.value)  { (snapshot)  in
            self.genreInfo = snapshot.value as? [[String:String]] ?? [[:]]
            userDefaults.set(self.genreInfo,forKey:"genreInfo")
            print("saved")
            self.genreCollecionView.reloadData()
        }


    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return genreInfo.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "genreCell", for: indexPath) as! GenreCollectionViewCell
        if let imageURL = URL(string: genreInfo[indexPath.item]["coverImage"] ?? "") {
            let downloadImageTask = URLSession.shared.dataTask(with: imageURL) { (data, response, error) in
                if let coverImage = UIImage(data: data ?? Data()) {
                    DispatchQueue.main.async {
                        cell.genreImageView.image = coverImage
                    }
                }
            }
            downloadImageTask.resume()
        }
        
        cell.genreLabel.text = genreInfo[indexPath.item]["displayName"]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let destinationVC = mainStoryboard.instantiateViewController(withIdentifier: "discoveryView") as! DiscoveryVC
        self.currentCategory = genreInfo[indexPath.item]
        destinationVC.currentCategory = genreInfo[indexPath.item]
        self.navigationController?.pushViewController(destinationVC, animated: false)
        
    }
    
    
}
