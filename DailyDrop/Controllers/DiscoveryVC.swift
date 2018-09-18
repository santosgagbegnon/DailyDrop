 //
//  DiscoveryViewController.swift
//  Daily Drop
//
//  Created by Santos on 2018-06-06.
//  Copyright © 2018 Santos. All rights reserved.
//

import Foundation
import UIKit
import PromiseKit
import AVFoundation
struct NextTrackInfo {
    let artists : String
    let imageURL : URL
    let trackName: String
    init(artists: String,imageURL: URL, trackName: String) {
        self.artists = artists
        self.imageURL = imageURL
        self.trackName = trackName
    }
 }
 protocol PassPopUpData : class {
    func playWholeTrack()
    func skipAlbum()
    func goToNextTrack()
 }
class DiscoveryVC: UIViewController,PassPopUpData, SPTAudioStreamingPlaybackDelegate, AVAudioPlayerDelegate {
    @IBOutlet weak var blurredAlbumArtBG: UIImageView!
    @IBOutlet weak var albumArtView: UIImageView!
    @IBOutlet weak var musicCard: UIView!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var playbackStatusButton: UIButton!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var audioProgressBar: UISlider!
    private let playImage = UIImage(named: "playbutton")
    private let pauseImage = UIImage(named: "pausedbutton")
    private var showingPlayImage = false
    private var OriginalYPosition:CGFloat = 0
    private var OriginalXPosition:CGFloat = 0
    static var currentSession : SPTSession?
    private var musicModel : SpotifyDiscoveryModel!
    var currentCategory = [String:String]()
    private var timeOutTimer = Timer()
    override func viewDidLoad() {
        musicCard.isHidden = true
        blurredAlbumArtBG.isHidden = true
        musicModel = SpotifyDiscoveryModel(discoveryView: self)
        OriginalYPosition = musicCard.frame.origin.y
        OriginalXPosition = musicCard.frame.origin.x
        self.navigationController?.navigationBar.topItem?.title = currentCategory["displayName"]
        let userDefaults = UserDefaults.standard
        let spotifySession = userDefaults.object(forKey: "SpotifySession")
        let spotifySessionObject = spotifySession as! Data

        DiscoveryVC.currentSession = NSKeyedUnarchiver.unarchiveObject(with: spotifySessionObject) as? SPTSession

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTapOccurred(_ :)))
        doubleTapGesture.numberOfTapsRequired = 2

        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(rightSwipeOccurred(_ :)))
        rightSwipeGesture.direction = UISwipeGestureRecognizerDirection.right
        
        let upSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(upSwipeOccurred(_ :)))
        upSwipeGesture.direction = UISwipeGestureRecognizerDirection.up
        
        musicCard.addGestureRecognizer(doubleTapGesture)
        musicCard.addGestureRecognizer(rightSwipeGesture)
        mainView.addGestureRecognizer(upSwipeGesture)
        self.musicModel.getNewMusic(fromGenre: self.currentCategory["name"]) {
            [weak self] in
            guard let `self` = self else { return}
            let firstTrack = self.switchToNextTrack()
            self.updateUI(newTrack: firstTrack)
            self.musicCard.isHidden = false
            self.blurredAlbumArtBG.isHidden = false

        }
        audioProgressBar.minimumTrackTintColor = UIColor(red: 54/255, green: 131/255, blue: 218/255, alpha: 1)
        audioProgressBar.maximumTrackTintColor = UIColor.white
        audioProgressBar.setThumbImage(UIImage(), for: .normal)
        audioProgressBar.setValue(0, animated: false)
       
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func playBackStatusButtonPressed(_ sender: UIButton) {
        if musicModel.getMusicIsOn() {
            playbackStatusButton.setImage(playImage, for: .normal)
            musicModel.pauseTrack()
        }
        else if !musicModel.getMusicIsOn() {
            if musicModel.getPreviewIsPlaying() {
                musicModel.playPreviewOfCurrentTrack()
            }
            else if musicModel.getFullTrackIsPlaying() {
                musicModel.playFullCurrenTrack()
            }
            playbackStatusButton.setImage(pauseImage, for: .normal)

        }
       
    }
    
    @objc func doubleTapOccurred(_ sender: UITapGestureRecognizer){
        let tapLocation = sender.location(in: playbackStatusButton)
        if (sender.state != UIGestureRecognizerState.ended || playbackStatusButton.layer.contains(tapLocation)){
            return
        }
        self.musicCard.backgroundColor = UIColor(red: 0/255, green: 190/255, blue: 0/255, alpha: 0.37)
        musicModel.addCurrentTrackToPlaylist(closure: {
            let newTrack = self.switchToNextTrack()
            self.animateMusicCard(track: newTrack)
        })

    }
    private func updateUI(newTrack : NextTrackInfo) {
        downloadAlbumImageFrom(url: newTrack.imageURL)
        self.artistNameLabel.text = newTrack.artists
        self.songTitleLabel.text = newTrack.trackName
        playbackStatusButton.setImage(pauseImage, for: .normal)

    }
    private func switchToNextTrack() -> NextTrackInfo {
        self.audioProgressBar.setValue(0, animated: false)
        self.timeOutTimer.invalidate()
        var imageURL : URL
        var artists = "No name"
        var trackName = "Untitled"
        var album : FIRAlbum
        var track : FIRTrack

        if var upNextDict = self.musicModel.trackIterator() {
            album = (upNextDict["album"] as? FIRAlbum ?? nil)!
            track = (upNextDict["track"] as? FIRTrack ?? nil)!
            trackName = track.name ?? "Untitled"
            imageURL = URL(string: album.images![0].url ?? "https://i.scdn.co/image/df2f1c6613a09f98f36d2dd1af56f6107707558d")!
            
            var artistsString = ""
            for (artistIndex,artist) in track.artists!.enumerated(){
                if artistIndex == track.artists!.count - 1 {
                    artistsString += artist.name!
                }
                else {
                    artistsString += artist.name! + ","
                }
            }
            artists = artistsString
           
            
        }else{
            let message = "You have listened to all the new music in {genreName} and will be redirected back to the genres menu!".replacingOccurrences(of: "{genreName}", with: currentCategory["displayName"] ?? "Error")
            self.musicCard.isHidden = true
            let alertController = UIAlertController(title: "No New Music", message: message, preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .default) { (action) in
                let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                let tabBarController = storyBoard.instantiateViewController(withIdentifier: "tabBarController") as! UITabBarController
                let genreViewController = tabBarController
                DispatchQueue.main.async {
                    self.present(genreViewController, animated: true, completion: nil)
                }
                    
                
            }
            alertController.addAction(action)
            self.present(alertController, animated: true, completion: nil)
            imageURL = URL(string:"https://i.scdn.co/image/df2f1c6613a09f98f36d2dd1af56f6107707558d")!
        }

        return NextTrackInfo(artists: artists, imageURL: imageURL, trackName: trackName)
    }

    @objc func rightSwipeOccurred(_ sender : UISwipeGestureRecognizer){
        
        if (sender.state != UIGestureRecognizerState.ended){
            return
        }
        let newTrack = switchToNextTrack()
        animateMusicCard(track: newTrack)
    }
    
    private func animateMusicCard(track : NextTrackInfo) {
        let sender = musicCard!
        let originalXPosition = sender.center.x
        UIView.animate(withDuration: 0.8, animations: {
            sender.center.x = sender.superview!.frame.maxX + sender.superview!.layer.bounds.width + sender.layer.bounds.width/2
        }) { (true) in
            self.musicCard.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.37)
            sender.center.x = 0 - sender.layer.bounds.width/2
            UIView.animate(withDuration: 0.3, delay: 0.2, animations: {
                [weak self] in
                guard let `self` = self else {return}
                sender.center.x = originalXPosition
                self.updateUI(newTrack: track)
            })
        }
        
    }
   
    @objc func upSwipeOccurred(_ sender : UISwipeGestureRecognizer){
        if (sender.state != UIGestureRecognizerState.ended){
            return
        }
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let popUpViewController = storyBoard.instantiateViewController(withIdentifier: "popUpView") as! MusicFeaturesVC
        popUpViewController.passDataProtocol = self
        self.present(popUpViewController, animated: false, completion: nil)
       
    }
    func skipAlbum() {
        musicModel.skipWholeAlbum()
        let newTrack = switchToNextTrack()
        animateMusicCard(track: newTrack)
        
    }
    func playWholeTrack() {
        musicModel.playFullCurrenTrack()
    }
    func downloadAlbumImageFrom(url : URL?) {
        guard let url = url else {return}
        let downloadTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error != nil {
                print(error?.localizedDescription ?? "nil")
            }
            guard let data = data else {return}
            let albumImage = UIImage(data: data)
            DispatchQueue.main.async {
                guard let albumImage = albumImage else {return}
                self.albumArtView.image = albumImage
                self.blurredAlbumArtBG.image = albumImage
            }
        }
        downloadTask.resume()
    }
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePosition position: TimeInterval) {
        self.audioProgressBar.setValue(Float(position), animated: false)
    }
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStartPlayingTrack trackUri: String!) {
        self.audioProgressBar.maximumValue = musicModel.getCurrentTrackLength() + 0.2
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStopPlayingTrack trackUri: String!) {
        self.audioProgressBar.setValue(0, animated: false)
        beginTimeOutTimer()

    }
    func previewTimerUpdate(time: Float) {
        DispatchQueue.main.async {
            self.audioProgressBar.setValue(Float(time), animated: false)

        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        musicModel.cancelTimer()
        
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.musicModel.cancelTimer()
        beginTimeOutTimer()
    }
    func updateProgressSlider(newTime : Float) {
        DispatchQueue.main.async {
            self.audioProgressBar.maximumValue = newTime
            self.audioProgressBar.setValue(0, animated: false)
        }
        
    }
    
    func goToNextTrack() {
        let newTrack = switchToNextTrack()
        animateMusicCard(track: newTrack)
    }
    func beginTimeOutTimer() {
         timeOutTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { (timer) in
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let popUpViewController = storyBoard.instantiateViewController(withIdentifier: "popUpView") as! MusicFeaturesVC
            popUpViewController.passDataProtocol = self
            popUpViewController.isTimedOutDisplay = true
            self.present(popUpViewController, animated: false, completion: nil)
        }
    }

    
  
    
}
