//
//  AppDelegate.swift
//  MoodController
//
//  Created by Jason Owens on 11/10/15.
//  Copyright © 2015 MoodMedia. All rights reserved.
//

import UIKit
import NetworkExtension

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var manager = NetworkManager.sharedInstance
    var globalNetworkList = [NEHotspotNetwork]()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        let theme = ThemeManager.currentTheme()
        ThemeManager.applyTheme(theme)
        NSUserDefaults.standardUserDefaults().setObject(nil, forKey: Constants.kProductsessionIdKey)
        NSUserDefaults.standardUserDefaults().synchronize()

        /**
            What's New in Network Extension and VPN: https://developer.apple.com/videos/play/wwdc2015-717/
            WWDC 2015 - Session 717 - OS X, iOS
        
        **/
        let bundleId = NSBundle.mainBundle().bundleIdentifier!
        var options:Dictionary<String, NSObject> = Dictionary(minimumCapacity: 1)
        options[kNEHotspotHelperOptionDisplayName] = Constants.kDescriptionWiFiAnnotation
        let queue:dispatch_queue_t = dispatch_queue_create(bundleId, DISPATCH_QUEUE_CONCURRENT)

        let _ = NEHotspotHelper.registerWithOptions(options, queue: queue, handler: {(command) -> Void in
            switch command.commandType {
                case .FilterScanList:
                    print("kNEHotspotHelperCommandFilterScanList")
                        self.globalNetworkList.removeAll()
                        for network in command.networkList! as [NEHotspotNetwork] {
                            if network.SSID.containsString(Constants.deviceName.uppercaseString) {
                                self.globalNetworkList.append(network)
                            }
                        }
                    let response = command.createResponse(.Success)
                    response.setNetworkList(self.globalNetworkList)
                    response.deliver()
                    
                    if self.globalNetworkList.count > 0 {
                        dispatch_async(dispatch_get_main_queue(), {
                            NSNotificationCenter.defaultCenter().postNotificationName("", object: nil)
                        })
                    }
                    break
                case .Evaluate:
                    print("kNEHotspotHelperCommandTypeEvaluate")
                    break
                case .None:
                    print("kNEHotspotHelperCommandTypeNone")
                    break
                case .Authenticate:
                    print("kNEHotspotHelperCommandTypeAuthenticate")
                    break
                case .PresentUI:
                    print("kNEHotspotHelperCommandTypePresentUI")
                    break
                case .Maintain:
                    print("kNEHotspotHelperCommandTypeMaintain")
                    break
                case .Logoff:
                    print("kNEHotspotHelperCommandTypeLogoff")
                    break
            }
        })        
    
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        print("applicationWillResignActive")
        dispatch_async(dispatch_get_main_queue(), {
            NSNotificationCenter.defaultCenter().postNotificationName(Constants.kNetworkManagerStopSearchingForServices, object:nil)
        })
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        print("applicationDidBecomeActive")
        dispatch_async(dispatch_get_main_queue(), {
            NSNotificationCenter.defaultCenter().postNotificationName(Constants.kNetworkManagerStartSearchingForServices, object:nil)
        })
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        print("applicationDidEnterBackground")
        
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        print("applicationWillEnterForeground")
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationWillTerminate(application: UIApplication) {
        print("applicationWillTerminate")
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

