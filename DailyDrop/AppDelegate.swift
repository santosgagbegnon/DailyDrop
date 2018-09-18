//
//  AppDelegate.swift
//  Daily Drop
//
//  Created by Santos on 2018-06-04.
//  Copyright © 2018 Santos. All rights reserved.
//

import UIKit
import Firebase
import StoreKit
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private let spotifyAuth = SPTAuth.defaultInstance()!
    private var currentlyRefreshing = false
    
    private let CLIENT_ID = "47c659b864ea41d8846d7e0339e12d74"
    private let CLIENT_SECRET = "213485efd4ad47028f1594c4931f2934"
    private let REDIRECT_URL = URL(string: "dailydrop://spotify/callback")
    private let TOKEN_SWAP_URL = URL(string:"https://secure-plains-51803.herokuapp.com/swap")
    private let TOKEN_REFRESH_URL = URL(string: "https://secure-plains-51803.herokuapp.com/refresh")
    private let SCOPES : [String] = [SPTAuthStreamingScope, SPTAuthUserReadTopScope, SPTAuthUserReadPrivateScope, SPTAuthPlaylistModifyPublicScope]
   
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        let mainStoryBoard = UIStoryboard(name: "Main", bundle: nil)
        let launchStoryBaord = UIStoryboard(name: "LaunchScreen", bundle: nil)
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        let tabBarController = mainStoryBoard.instantiateViewController(withIdentifier: "tabBarController") as! UITabBarController
        let loadingViewController = launchStoryBaord.instantiateViewController(withIdentifier: "loadingScreenView")
        self.window?.rootViewController = loadingViewController
        let userDefaults = UserDefaults.standard
        
        //Check if spotify already logged in logged in
        if currentlyRefreshing == true {return true}
        if let spotifySession = userDefaults.object(forKey: "SpotifySession"){
            let spotifySessionObject = spotifySession as! Data
            let currentSession = NSKeyedUnarchiver.unarchiveObject(with: spotifySessionObject) as! SPTSession
            if !currentSession.isValid() {
                print("Currently Renewing Session")
                currentlyRefreshing = true
                spotifyAuth.clientID = CLIENT_ID
                spotifyAuth.redirectURL = REDIRECT_URL
                spotifyAuth.tokenSwapURL = TOKEN_SWAP_URL
                spotifyAuth.tokenRefreshURL = TOKEN_REFRESH_URL

                spotifyAuth.renewSession(currentSession, callback: {
                    error, session in

                    if error != nil {
                        print("error refreshing session")
                        print(error.debugDescription)
                        return
                    }
                    print("Session renewed")
                    self.window?.makeKeyAndVisible()

                    SpotifyDiscoveryModel.sptSession = session!
                    DiscoveryVC.currentSession = session!

                    let userDefaults = UserDefaults()
                    let sessionData = NSKeyedArchiver.archivedData(withRootObject: session!)
                    userDefaults.set(sessionData, forKey: "SpotifySession")
                    userDefaults.synchronize()
                    self.window?.rootViewController = tabBarController
                    self.currentlyRefreshing = false
                    
                })
            }
            else {
                window?.rootViewController = tabBarController
            }
           
        }
        else { //Have not yet logged in
            let logInView = mainStoryBoard.instantiateViewController(withIdentifier: "logInView")
            window?.rootViewController = logInView
        }
        return true
    }
    
   

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("didBecomeActive")
        let mainStoryBoard = UIStoryboard(name: "Main", bundle: nil)
        let launchStoryBoard = UIStoryboard(name: "LaunchScreen", bundle: nil)
        let userDefaults = UserDefaults.standard
        let logInView = mainStoryBoard.instantiateViewController(withIdentifier: "logInView")
        let loadingViewController = launchStoryBoard.instantiateViewController(withIdentifier: "loadingScreenView")
        if currentlyRefreshing == true {return }
        
        if let spotifySession = userDefaults.object(forKey: "SpotifySession"){
            let spotifySessionObject = spotifySession as! Data
            let currentSession = NSKeyedUnarchiver.unarchiveObject(with: spotifySessionObject) as! SPTSession
            if !currentSession.isValid() {
                self.window?.rootViewController = loadingViewController
                print("Currently Renewing Session")
                currentlyRefreshing = true
                spotifyAuth.clientID = CLIENT_ID
                spotifyAuth.redirectURL = REDIRECT_URL
                spotifyAuth.tokenSwapURL = TOKEN_SWAP_URL
                spotifyAuth.tokenRefreshURL = TOKEN_REFRESH_URL
                spotifyAuth.renewSession(currentSession, callback: {
                    error, session in
                    let tabBarController = mainStoryBoard.instantiateViewController(withIdentifier: "tabBarController") as! UITabBarController
                    if error != nil {
                        print("error refreshing session")
                        print(error.debugDescription)
                        return
                    }
                    print("Session renewed")
                    self.window?.makeKeyAndVisible()
                    SpotifyDiscoveryModel.sptSession = session!
                    DiscoveryVC.currentSession = session!
                    let userDefaults = UserDefaults()
                    let sessionData = NSKeyedArchiver.archivedData(withRootObject: session!)
                    userDefaults.set(sessionData, forKey: "SpotifySession")
                    userDefaults.synchronize()
                    self.window?.rootViewController = tabBarController
                    self.currentlyRefreshing = false
                    
                })
            }
        }
        else { //Have not yet logged in
            window?.rootViewController = logInView
        }
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

