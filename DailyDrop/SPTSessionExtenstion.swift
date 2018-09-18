//
//  SPTSessionExtenstion.swift
//  Daily Drop
//
//  Created by Santos on 2018-06-22.
//  Copyright © 2018 Santos. All rights reserved.
//

import Foundation
import PromiseKit


private struct SPTParams {
    let limit = "limit"
    let market = "market"
    let offset = "offset"
    let include = "include_groups"
    let ID = "ID"
    let auth = "Authorization"
    let bearer = "Bearer "
    let time = "time_range"
    let type = "type"
    let name = "name"
    let pub = "public"
    let collaborative = "collaborative"
    let description = "description"
    
}
extension SPTSession {
    struct SPTInfo {
        static let CLIENT_ID = "47c659b864ea41d8846d7e0339e12d74"
        static let CLIENT_SECRET = "213485efd4ad47028f1594c4931f2934"
        static let REDIRECT_URL = URL(string: "dailydrop://spotify/callback")
        static let TOKEN_SWAP_URL = URL(string:"https://secure-plains-51803.herokuapp.com/swap")
        static let TOKEN_REFRESH_URL = URL(string: "https://secure-plains-51803.herokuapp.com/refresh")
        static let SCOPES : [String] = [SPTAuthStreamingScope, SPTAuthUserReadTopScope, SPTAuthUserReadPrivateScope, SPTAuthPlaylistModifyPublicScope]
    }

    //Playlists
    func getUsersPlaylists(user_id : String,limit: Int = 50,offset : Int = 0) -> Promise<(playlists: [SPTPartialPlaylist]?, response: URLResponse)>{
        let limit = inRangeInteger(x: limit, min: 0, max: 50)
        var offset = offset
        if offset < 0 {
            offset = 0
        }
        let urlBase = "https://api.spotify.com/v1/users/{user_id}/playlists".replacingOccurrences(of: "{user_id}", with: user_id)
        let keywords = SPTParams()
        let headers = [keywords.auth: keywords.bearer + self.accessToken]
        let params = [keywords.limit:String(limit), keywords.offset:String(offset)]
        var urlComponents = URLComponents(string: urlBase)
        var queryItems = [URLQueryItem]()
        for (key,value) in params {
            let queryItem = URLQueryItem(name: key, value: value)
            queryItems.append(queryItem)
        }
        urlComponents?.queryItems = queryItems
        
        var apiRequest = URLRequest(url: (urlComponents?.url)!)
        apiRequest.httpMethod = "GET"
        for (key,value) in headers {
            apiRequest.setValue(value, forHTTPHeaderField: key)
        }
        return URLSession.shared.dataTask(.promise, with: apiRequest).then {
            (data,response) -> Promise<(playlists: [SPTPartialPlaylist]?, response: URLResponse)> in
            var playlists : [SPTPartialPlaylist]?
            do {
                let playlistObject = try SPTPlaylistList.init(from: data, with: response)
                playlists = playlistObject.items as? [SPTPartialPlaylist]
            }
            catch {
                print("Error parsing data into a SPTPartial Playlist")
            }
            
            return Promise.value((playlists, response))
        }

    }
    func addTrackto(_ playlistID: String, _ userID: String, _ uris: [String] = [], _ position : Int = 0){
        let keywords = SPTParams()
        let urlBase = "https://api.spotify.com/v1/playlists/{playlist_id}/tracks".replacingOccurrences(of: "{playlist_id}", with: playlistID)
        let headers = [keywords.auth: keywords.bearer + self.accessToken]
        var urlComponents = URLComponents(string: urlBase)
        var params = [String:String]()
        var uriString = ""
        for (n,_) in uris.enumerated() {
            if n != uris.count-1 {
                uriString += uris[n] + ","
            }
            else{
                uriString += uris[n]
            }
        }
        params["uris"] = uriString
        params["position"] = String(position)

        var queryItems = [URLQueryItem]()
        for (key,value) in params {
            let queryItem = URLQueryItem(name: key, value: value)
            queryItems.append(queryItem)
        }
        urlComponents?.queryItems = queryItems
        var apiRequest = URLRequest(url: (urlComponents?.url)!)
        apiRequest.httpMethod = "POST"

        for (key,value) in headers {
            apiRequest.setValue(value, forHTTPHeaderField: key)
        }
        URLSession.shared.dataTask(.promise, with: apiRequest).done {
            (_,response) in
            let resp = response as? HTTPURLResponse
            if resp?.statusCode != 201 {
                print("error adding track:", resp?.statusCode ?? "nil", response)
            }
            }.catch { (error) in
                print("Add to track failed:",error.localizedDescription)
        }
    }
    
    func createPlaylist(forUserID userID: String, named name: String,  isPublic: Bool = true,  isCollaborative: Bool = false,  descrption: String?) -> Promise<String?>{
        let keywords = SPTParams()
        let urlBase = "https://api.spotify.com/v1/users/{user_id}/playlists".replacingOccurrences(of: "{user_id}", with: userID)
        let headers = [keywords.auth: keywords.bearer + self.accessToken]
        let urlComponents = URLComponents(string: urlBase)
        let json = [
            "name": name,
            "public" : String(isPublic),
            "collaborative": String(isCollaborative),
            "description": description,
        ]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        var apiRequest = URLRequest(url: (urlComponents?.url)!)
        apiRequest.httpMethod = "POST"
        apiRequest.httpBody = jsonData
        for (key,value) in headers {
            apiRequest.setValue(value, forHTTPHeaderField: key)
        }
        return URLSession.shared.dataTask(.promise, with: apiRequest).then {
            (data,response) -> Promise<String?> in
            var playlist : SPTPlaylistSnapshot?
            do {
                playlist = try SPTPlaylistSnapshot.init(from: data, with: response)
            }
            catch let err as NSError{
                print("error creating playlist",err.localizedDescription, response)
            }
            
            
            return Promise.value(self.getIDfromURI(uri: playlist?.uri.absoluteString))
        }
    }

    private func inRangeInteger(x: Int, min: Int, max: Int) -> Int{
        if x < min {
            return min
        }
        if max == -1 {
            return x
        }
        
        if x > max {
            return max
        }
        
        return x
        
    }
    private func getIDfromURI(uri: String?) -> String? {
        guard let uri = uri else {return nil}
        var splitArray = uri.components(separatedBy: ":")
        return splitArray[splitArray.count-1]
    }

    
}
