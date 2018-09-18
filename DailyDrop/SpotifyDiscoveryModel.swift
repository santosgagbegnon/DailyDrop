//
//  MusicDiscoveryModel.swift
//  Daily Drop
//
//  Created by Santos on 2018-06-28.
//  Copyright © 2018 Santos. All rights reserved.
//

import Foundation
import PromiseKit
import Firebase
import AVFoundation
class SpotifyDiscoveryModel {
    private var allAlbums = [FIRAlbum]()
    private var currentAlbum: FIRAlbum?
    private var currentTrackIndex = -1
    private var currentTracklist = [FIRTrack]()
    private var currentTrackPosition : Double
    private weak var discoveryViewController : DiscoveryVC?
    private let fullPlayer = SPTAudioStreamingController.sharedInstance()
    private var fullTrackIsPlaying = false
    private var history = [String]()
    private var id : String?
    private var musicIndex = 0
    private var musicIsOn = false
    private var name : String?
    var playWholeAlbum = false
    private var previewAudioTime = Float(0.0)
    private var previewAudioTimer = Timer()
    private var previewIsPlaying = false
    private var previewPlayer : AVAudioPlayer?
    var ref = Database.database().reference().child("server")
    static var sptSession = SPTSession()
    private var targetPlaylistID : String?
    private var userLocation : String?

    init(discoveryView : DiscoveryVC) {
        let userDefaults = UserDefaults.standard
        targetPlaylistID = userDefaults.object(forKey: "TargetPlaylistID") as? String
        //Saving history
       // history = userDefaults.object(forKey: "UserListeningHistory") as? [String] ?? [String]()
        
        if targetPlaylistID?.count == 0 {
            targetPlaylistID = nil
        }
        let spotifySession = userDefaults.object(forKey: "SpotifySession")
        let spotifySessionObject = spotifySession as! Data
        discoveryViewController = discoveryView
        currentTrackPosition = 0.0
        SpotifyDiscoveryModel.sptSession = NSKeyedUnarchiver.unarchiveObject(with: spotifySessionObject) as! SPTSession
        let locationRequestURL = try? SPTUser.createRequestForCurrentUser(withAccessToken: SpotifyDiscoveryModel.sptSession.accessToken!)
        let userLocationRequest = URLSession.shared.dataTask(with: locationRequestURL!) { (data, response, err) in
            if err != nil {
                print(err?.localizedDescription ?? "error is nil")
                return
            }
            do {
                let currentUser = try SPTUser(from: data, with: response)
                self.userLocation = currentUser.territory
                self.id = currentUser.canonicalUserName
                self.name = currentUser.displayName ?? ""
            }
            catch let error as NSError {
                print(error.localizedDescription)
            }
            return
        }
        userLocationRequest.resume()
        try? fullPlayer?.start(withClientId: SPTSession.SPTInfo.CLIENT_ID)
        fullPlayer?.login(withAccessToken: SpotifyDiscoveryModel.sptSession.accessToken)
        fullPlayer?.playbackDelegate = discoveryView
        
    }
  
    func getNewMusic(fromGenre genre : String?, closure: @escaping ()->Void){
        guard let genre = genre else {return}
        ref = Database.database().reference().child("server").child(genre).child("music")
        ref.observeSingleEvent(of:.value)  { (snapshot)  in
            let snapArray = snapshot.value as? [AnyObject] ?? []
            for track in snapArray {
                let newAlbum = FIRAlbum(dictionary: track as? [String:AnyObject] ?? [:])
                self.allAlbums.append(newAlbum)
            }
            closure()
        }
    }
    /******************************
     *    FEATURE FUNCTIONS
     *******************************/
    func addCurrentTrackToPlaylist( closure: @escaping ()->Void) {
        guard let userID = self.id else {return}
        SpotifyDiscoveryModel.sptSession.getUsersPlaylists(user_id: userID).then { (playlists,response) -> Promise<String?> in
            guard let savedPlaylistID = self.targetPlaylistID else {return Promise.value(nil)}
            if let allPlaylists = playlists {
                for playlist in allPlaylists {
                    let id = self.getIDfromURI(uri: playlist.uri.absoluteString)
                    if savedPlaylistID == id{
                        return Promise.value(savedPlaylistID)
                    }
                }
            }
            return Promise.value(nil)
            }.then{(playlistID) -> Promise<String?> in
                if let id = playlistID { return Promise.value(id)}
                return SpotifyDiscoveryModel.sptSession.createPlaylist(forUserID: userID, named: "My Daily Drop Discoveries!", isPublic: true, isCollaborative: false, descrption: "Best playlist ever!")
            }.done { (playlistID) in
                guard let playlistID = playlistID else {return}
                guard let trackID = self.currentTracklist[self.currentTrackIndex].uri else {return}
                let userDefaults = UserDefaults.standard
                userDefaults.set(playlistID, forKey: "TargetPlaylistID")
                self.targetPlaylistID = playlistID
                SpotifyDiscoveryModel.sptSession.addTrackto(playlistID, userID, [trackID])
                closure()
            }.catch { (error) in
                print("error in adding track to playlist promise chain:", error.localizedDescription)
            }
    }
    func skipWholeAlbum(){
        guard let tracks = currentAlbum?.tracks?.items else {return}
        for track in tracks {
            if let trackString = generateTrackString(track: track) {history.append(trackString) }
        }
        currentTrackIndex = currentTracklist.count-1
    }
    
    private func getIDfromURI(uri: String?) -> String {
        guard let uri = uri else {return ""}
        var splitArray = uri.components(separatedBy: ":")
        return splitArray[splitArray.count-1]
    }
    
    /******************************
     *    TRACK / ALBUM FUNCTIONS
     *******************************/
    private func nextAlbum() -> FIRAlbum?{
        musicIndex += 1
        if musicIndex > allAlbums.count {
            print("End of array")
            return nil
        }
        return allAlbums[musicIndex-1]
    }
    
    private func nextTrack() -> [String:Any]? {
        if currentTracklist.count == 0 || currentTrackIndex == currentTracklist.count-1{
            currentAlbum = nextAlbum()
            if currentAlbum == nil {return nil}
            currentTrackIndex = 0
            currentTracklist = currentAlbum?.tracks?.items ?? []
        }
        else{
            currentTrackIndex += 1
        }
        if currentTrackIndex >= currentTracklist.count {return nil}
        return ["track":currentTracklist[currentTrackIndex] ,"album":currentAlbum as Any]
        
    }
    
    func trackIterator() -> [String:Any]?{
        if previewPlayer?.isPlaying == true {
            previewPlayer?.stop()
        }
        if fullPlayer?.playbackState?.isPlaying == true{
            pauseFullCurrentTrack()
        }
        currentTrackPosition = 0.0
        previewIsPlaying = false
        fullTrackIsPlaying = false
        musicIsOn = false
        var trackAndAlbum : [String:Any]?
        trackAndAlbum = nextTrack()
        if trackAndAlbum == nil {return nil}

        var currentTrack = currentTracklist[currentTrackIndex]
        while !(verifyTrack(track:currentTrack, target: currentAlbum?.requestFrom)) {
            trackAndAlbum = nextTrack()
            currentTrack = currentTracklist[currentTrackIndex]
            if trackAndAlbum == nil {return nil}
        }
        if let trackString = generateTrackString(track: currentTracklist[currentTrackIndex]) { history.append(trackString)}

        playPreviewOfCurrentTrack()
        return trackAndAlbum
    }
    func getNumOfTracks()-> Int{
        return allAlbums.count
    }
    
    private func generateTrackString(track : FIRTrack) -> String?{
        var trackString = ""
        if let artists = track.artists {
            trackString = ""
            let trackName = track.name ?? ""
            for artist in artists {
                trackString += artist.name ?? ""
            }
            return (trackName+trackString).replacingOccurrences(of: " ", with: "")
        }
        return nil
    }
    
    private func verifyTrack(track : FIRTrack,target: String? ) -> Bool{
        if target == nil {
            print("target nil in verify track")
            return false
        }
        var artistIDFound = false
        var locationFound = false
        guard let allArtists = track.artists else { return false}
        guard let trackString = generateTrackString(track: track) else {return false}
        guard let locations = track.available_markets  else {return false}
        if history.contains(trackString) {return false}
        if track.preview_url == "" {return false}
        for artist in allArtists {

            if artist.id == target {
                artistIDFound = true
            }
        }
        for location in locations {
            if location == userLocation {
                locationFound = true
                
            }
        }
        return locationFound && artistIDFound
    }

    
/******************************
*    AUDIO PLAYING FUNCTIONS
*******************************/
    func pauseFullCurrentTrack() {
        currentTrackPosition = fullPlayer?.playbackState?.position ?? 0.0
        fullPlayer?.setIsPlaying(false, callback: { (_) in
            self.musicIsOn = false
        })
    }
    
    func pauseTrack() {
        if previewIsPlaying {
           _ = pausePreviewOfCurrentTrack()
        }
        if fullTrackIsPlaying {
            pauseFullCurrentTrack()
        }
        musicIsOn = false
    }
    func pausePreviewOfCurrentTrack() -> Bool? {
        previewPlayer?.pause()
        self.musicIsOn = false
        self.previewAudioTimer.invalidate()
        return previewPlayer?.isPlaying
    }
   
    func playFullCurrenTrack() {
        if previewPlayer?.isPlaying == true {
            previewPlayer?.stop()
            previewAudioTimer.invalidate()
            previewIsPlaying = false
            musicIsOn = false
        }
        if fullPlayer?.playbackState?.isPlaying == true{
            fullTrackIsPlaying = true
            musicIsOn = true
            return
        }
        guard let uri = currentTracklist[currentTrackIndex].uri else {return}
        fullPlayer?.playSpotifyURI(uri, startingWith: 0, startingWithPosition: currentTrackPosition, callback: { (err) in
            if err != nil {
                print(err.debugDescription)
            }
            self.fullTrackIsPlaying = true
            self.musicIsOn = true
        })
    }
   
 
    func playPreviewOfCurrentTrack()  {
        previewAudioTimer.invalidate()
        if previewPlayer?.isPlaying == false && previewIsPlaying {
            //Continue playing song
            runPreviewAudioTimer()
            previewPlayer?.play()
            musicIsOn = true
            return
        }
        if previewPlayer?.isPlaying == true {
            runPreviewAudioTimer()
            previewIsPlaying = true
            musicIsOn = true
            return
        }
        if fullPlayer?.playbackState?.isPlaying == true{
            fullPlayer?.setIsPlaying(false, callback: { (_) in
                self.musicIsOn = false
                self.fullTrackIsPlaying = false
                self.currentTrackPosition = 0.0
            })
            
        }
        guard let preview_string = currentTracklist[currentTrackIndex].preview_url else {return }
        guard let preview_url = URL(string: preview_string) else {return}
 
        let downloadTask = URLSession.shared.downloadTask(with: preview_url) { (url, response, err) in
            if err != nil {
                print(err?.localizedDescription ?? "error is nil, but got into if statement")
            }
            self.previewAudioTime = 0.0
            self.previewPlayer = try? AVAudioPlayer(contentsOf: url!)
            self.previewPlayer?.delegate = self.discoveryViewController
            self.previewPlayer?.prepareToPlay()
            if let duration = self.previewPlayer?.duration {
                self.discoveryViewController?.updateProgressSlider(newTime: Float(duration))
            }
            self.previewPlayer?.play()
            self.runPreviewAudioTimer()
            self.previewIsPlaying = true
            self.musicIsOn = true
        }
        downloadTask.resume()
    }
   
    
    func getPreviewIsPlaying() -> Bool {
        return previewIsPlaying

    }
    func getFullTrackIsPlaying() -> Bool {
        return fullTrackIsPlaying
    }
    func getMusicIsOn() -> Bool {
        return musicIsOn
    }
    func getCurrentTrackLength() ->  Float {
        guard let trackLength = currentTracklist[currentTrackIndex].duration_ms else {return 0.0}
        let trackLengthSeconds = Double(trackLength) * 0.001
        return Float(trackLengthSeconds)
    }
    @objc func previewTimerUpdate() {
        self.previewAudioTime += 0.01
        self.discoveryViewController?.previewTimerUpdate(time: self.previewAudioTime)
    }
   
    func runPreviewAudioTimer() {
        DispatchQueue.main.async {
            self.previewAudioTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(SpotifyDiscoveryModel.previewTimerUpdate), userInfo: nil, repeats: true)
        }
    }
    func cancelTimer() {
        self.previewAudioTimer.invalidate()
    }
    
    deinit {
        let userDefaults = UserDefaults.standard
        userDefaults.set(self.history, forKey: "UserListeningHistory")
    }
 
}
