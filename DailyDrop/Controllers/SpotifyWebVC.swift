//
//  LogInViewController.swift
//  Daily Drop
//
//  Created by Santos on 2018-06-14.
//  Copyright © 2018 Santos. All rights reserved.
//
import Foundation
import WebKit

class SpotifyWebVC:UIViewController, WKNavigationDelegate {
    
    @IBOutlet weak var SpotifyWebView: WKWebView!
    let spotifyAuth = SPTAuth.defaultInstance()!
    
    private let CLIENT_ID = "47c659b864ea41d8846d7e0339e12d74"
    private let CLIENT_SECRET = "0db38f8e0d5f4d0590990f5af5b50234"
    private let REDIRECT_URL = URL(string: "dailydrop://spotify/callback")
    private let TOKEN_SWAP_URL = URL(string:"https://secure-plains-51803.herokuapp.com/swap")
    private let TOKEN_REFRESH_URL = URL(string: "https://secure-plains-51803.herokuapp.com/refresh")
    private let SCOPES : [String] = [SPTAuthStreamingScope, SPTAuthUserReadTopScope, SPTAuthUserReadPrivateScope, SPTAuthPlaylistModifyPublicScope]
    
    override func viewDidLoad() {
        spotifyAuth.clientID = CLIENT_ID
        spotifyAuth.redirectURL = REDIRECT_URL
        spotifyAuth.tokenSwapURL = TOKEN_SWAP_URL
        spotifyAuth.tokenRefreshURL = TOKEN_REFRESH_URL
        let link = SPTAuth.loginURL(forClientId: spotifyAuth.clientID, withRedirectURL: spotifyAuth.redirectURL!, scopes: SCOPES, responseType: "code")
        let linkRequest =  URLRequest(url: link!)
        let notificationName = NSNotification.Name("loginSuccessfull")
        NotificationCenter.default.addObserver(self, selector: #selector(updateAfterFirstLoginSuccess), name: notificationName, object: nil)
        SpotifyWebView.navigationDelegate = self
        SpotifyWebView.load(linkRequest)
        
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let navURL = navigationAction.request.url!
        
        if (spotifyAuth.canHandle(navURL)){
            spotifyAuth.handleAuthCallback(withTriggeredAuthURL: navURL, callback: {
                error,session in
                if error != nil {
                    print("Authentication Error Occurred")
                    print(error!.localizedDescription)
                    return
                }
                
                let userDefaults = UserDefaults()
                let sessionData = NSKeyedArchiver.archivedData(withRootObject: session!)
                let notificationName = NSNotification.Name("loginSuccessfull")
                userDefaults.set(true,forKey:"IsSpotifyUser")
                userDefaults.set(sessionData, forKey: "SpotifySession")
                NotificationCenter.default.post(name: notificationName, object: nil)
            })
        }
      
        decisionHandler(.allow)
    }
    
    
    @objc func updateAfterFirstLoginSuccess(){
        //Move to disocery
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        
        let tabBarController = storyBoard.instantiateViewController(withIdentifier: "tabBarController") as! UITabBarController
        let discoveryViewController = tabBarController

        self.present(discoveryViewController, animated: false, completion:nil)
    }
}
