//
//  Alerts.swift
//  MoodController
//
//  Created by Jason Owens on 2/1/16.
//  Copyright © 2016 MoodMedia. All rights reserved.
//

import Foundation
import UIKit


class Alerts {
    var alert:UIAlertController?
    
    func showErrorAlert(data:[String:AnyObject]) -> UIAlertController {
        if let title = data[Constants.kConstantTitleText] as? String {
            if let message = data[Constants.kConstantMessageText] as? String {
                alert = UIAlertController(title:title, message:message, preferredStyle:.Alert)
                let cancelBtn = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
                alert!.addAction(cancelBtn)
            }
        }
        return alert!
    }
    
    func showSettingsAppAlertView() -> UIAlertController {
        let title = Constants.kAlertSettingsRedirectTitle
        let message = Constants.kAlertSettingsRedirectMessage
        
        alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let cancelBtn = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        let settingsBtn = UIAlertAction(title: "Settings", style: .Default) { (UIAlertAction) -> Void in
            if let url = NSURL(string: UIApplicationOpenSettingsURLString) {
                dispatch_async(dispatch_get_main_queue(), {
                    UIApplication.sharedApplication().openURL(url)
                })
            }
        }
        alert!.addAction(cancelBtn)
        alert!.addAction(settingsBtn)
        
        return alert!
    }
}