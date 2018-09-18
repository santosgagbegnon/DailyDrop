//
//  FirebaseStructs.swift
//  Daily Drop
//
//  Created by Santos on 2018-08-09.
//  Copyright © 2018 Santos. All rights reserved.
//

import Foundation
struct FIRAlbum : Decodable {
    var album_type : String?
    var artists : [FIRSimpleArtist]?
    var available_markets : [String]?
    var copyrights : [[String:String]]?
    var external_ids : [String:String]?
    var external_urls: [String:String]?
    var href : String?
    var id: String?
    var images : [FIRImage]?
    var label : String?
    var popularity : Int?
    var name: String?
    var release_date : String?
    var release_date_precision: String?
    var requestFrom: String?
    var total_tracks : Int?
    var tracks : FIRTracksRoot?
    var type : String?
    var uri : String?
    
    init(dictionary: [String:AnyObject]){
        self.album_type = dictionary["album_type"] as? String ?? ""
        self.artists = [FIRSimpleArtist]()
        let artists = dictionary["artists"] as? [AnyObject] ?? []
        for object in artists {
            let artist = object as? [String:AnyObject] ?? [:]
            self.artists?.append(FIRSimpleArtist(dictionary: artist))
        }
        self.available_markets = dictionary["available_markets"] as? [String] ?? []
        self.copyrights = dictionary["copyrights"] as? [[String:String]] ?? []
        self.external_ids = dictionary["external_ids"] as? [String:String] ?? [:]
        self.external_urls = dictionary["external_urls"] as? [String:String] ?? [:]
        self.href = dictionary["href"] as? String ?? ""
        self.id = dictionary["id"] as? String ?? ""
        let images = dictionary["images"] as? [AnyObject] ?? []
        self.images = [FIRImage]()
        for object in images {
            let image = object as? [String:AnyObject] ?? [:]
            self.images?.append(FIRImage(dictionary: image))
        }
        self.label = dictionary["label"] as? String ?? ""
        self.popularity = dictionary["popularity"] as? Int ?? 0
        self.name = dictionary["name"] as? String ?? ""
        self.release_date = dictionary["release_date"] as? String ?? ""
        self.release_date_precision = dictionary["release_date_precision"] as? String ?? ""
        self.requestFrom = dictionary["requestFrom"] as? String ?? ""
        self.total_tracks = dictionary["total_tracks"] as? Int ?? 0
        self.tracks = FIRTracksRoot(dictionary: dictionary["tracks"] as? [String:AnyObject] ?? [:])
        self.type = dictionary["type"] as? String ?? ""
        self.uri = dictionary["uri"] as? String ?? ""
        
    }
    
}

struct FIRGenres {
    static let new_wave = "new wave"
    static let trap = "trap"
    static let og_music = "og music"
    static let lyrical_rap = "lyrical rap"
    static let rowdy_rap = "rowdy rap"
    static let emotional = "emotional"
    static let canadian_rap = "canadian rap"
    static let uk_rap = "uk rap"
    static let souther_usa = "southerna usa"
    static let east_coast_usa = "east coast usa"
    static let west_coast_usa = "west coast usa"
    static let chicago = "chicago"
    static let low_keys = "the low-keys"
}

struct FIRImage: Decodable {
    var height : String?
    var url : String?
    var width: String?
    
    init(dictionary: [String: AnyObject]){
        self.height = dictionary["height"] as? String ?? ""
        self.url = dictionary["url"] as? String ?? ""
        self.width = dictionary["width"] as? String ?? ""
    }
    
}

struct FIRSimpleArtist : Decodable {
    var external_urls : [String:String]?
    var href : String?
    var id : String?
    var name : String?
    var type : String?
    var uri : String?
    
    init(dictionary: [String:AnyObject]){
        self.external_urls = dictionary["external_urls"] as? [String:String] ?? [:]
        self.href = dictionary["href"] as? String ?? ""
        self.id = dictionary["id"] as? String ?? ""
        self.name = dictionary["name"] as? String ?? ""
        self.type = dictionary["type"] as? String ?? ""
        self.uri = dictionary["uri"] as? String ?? ""
    }
}

struct FIRTrack : Decodable {
    var artists : [FIRSimpleArtist]?
    var available_markets : [String]?
    var disc_numbers : Int?
    var duration_ms : Int?
    var explicit : Bool?
    var external_urls: [String:String]?
    var href : String?
    var id: String?
    var is_local : Bool?
    var name: String?
    var preview_url : String?
    var track_number: Int?
    var type: String?
    var uri: String?

    init(dictionary: [String:AnyObject]){
        self.artists = [FIRSimpleArtist]()
        let artists = dictionary["artists"] as? [AnyObject] ?? []
        for object in artists {
            let artist = object as? [String:AnyObject] ?? [:]
            self.artists?.append(FIRSimpleArtist(dictionary: artist))
        }
        self.available_markets = dictionary["available_markets"] as? [String] ?? []
        self.disc_numbers = dictionary["disc_numbers"] as? Int ?? 0
        self.duration_ms = dictionary["duration_ms"] as? Int ?? 0
        self.explicit = dictionary["explicit"] as? Bool ?? true
        self.external_urls = dictionary["external_urls"] as? [String:String] ?? [:]
        self.href = dictionary["href"] as? String ?? ""
        self.id = dictionary["id"] as? String ?? ""
        self.is_local = dictionary["is_local"] as? Bool ?? false
        self.name = dictionary["name"] as? String ?? ""
        self.preview_url = dictionary["preview_url"] as? String ?? ""
        self.type = dictionary["type"] as? String ?? ""
        self.uri = dictionary["uri"] as? String ?? ""
    }
}

struct FIRTracksRoot : Decodable {
    var href : String?
    var items : [FIRTrack]?
    var limit : Int?
    var offset: Int?
    var total: Int?
    
    init(dictionary: [String:AnyObject]){
        self.href = dictionary["href"] as? String ?? ""
        self.items = [FIRTrack]()
        let tracks = dictionary["items"] as? [AnyObject] ?? []
        for object in tracks {
            let track = object as? [String:AnyObject] ?? [:]
            self.items?.append(FIRTrack(dictionary: track))
        }
        self.limit = dictionary["limit"] as? Int ?? 0
        self.offset = dictionary["offset"] as? Int ?? 0
        self.total = dictionary["total"] as? Int ?? 0
        
    }

}


