//
//  AppDelegate.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 20/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import Fabric
import CoreSpotlight
import Crashlytics
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit
import GoogleSignIn
import ManaKit
import MMDrawerController
import OAuthSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print("docsPath = \(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])")

        // Firebase
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID

        // Facebook
        FBSDKApplicationDelegate.sharedInstance().application(application,
                                                               didFinishLaunchingWithOptions: launchOptions)

        // Fabric
        Fabric.with([Crashlytics.self])

        // ManaKit
        ManaKit.sharedInstance.setupResources()
        ManaKit.sharedInstance.configureTCGPlayer(partnerKey: TCGPlayerSettings.PartnerKey,
                                                  publicKey: TCGPlayerSettings.PublicKey,
                                                  privateKey: TCGPlayerSettings.PrivateKey)
        // Set the global tint color
        window?.tintColor = LookAndFeel.GlobalTintColor
        
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
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        var handled = false
        
        if url.absoluteString.hasPrefix("fb") {
            handled = FBSDKApplicationDelegate.sharedInstance().application(app,
                                                                            open: url,
                                                                            options: options)
        } else if url.absoluteString.hasPrefix("com.googleusercontent.apps") {
            handled = GIDSignIn.sharedInstance().handle(url,
                                                        sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                                                        annotation: options[UIApplication.OpenURLOptionsKey.annotation])
        } else if (url.host == "oauth-callback") {
            OAuthSwift.handle(url: url)
            handled = true
        }
        
        return handled
    }
    
    
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if let rootVC = window?.rootViewController as? MMDrawerController,
            let tabBarVC = rootVC.centerViewController as? UITabBarController,
            let viewControllers = tabBarVC.viewControllers,
            let nvc = viewControllers[tabBarVC.selectedIndex] as? UINavigationController,
            let vc = nvc.topViewController as? BaseViewController {
            vc.restoreUserActivityState(userActivity)
        }
        
//        if let nav = window?.rootViewController as? UINavigationController {
//            if let cardVC = nav.children.first as? CardViewController {
//                cardVC.restoreUserActivityState(userActivity)
//            }
//        } else if let cardVC = window?.rootViewController as? CardViewController {
//            cardVC.restoreUserActivityState(userActivity)
//        }
    
        return true
    }
}

