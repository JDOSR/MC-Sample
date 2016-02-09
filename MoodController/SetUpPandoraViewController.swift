//
//  SetUpPandoraViewController.swift
//  MoodController
//
//  Created by Jason Owens on 12/11/15.
//  Copyright © 2015 MoodMedia. All rights reserved.
//

import Foundation
import UIKit

class SetUpPandoraViewController : UIViewController
{
    
    @IBOutlet var indicator: UIActivityIndicatorView!
    @IBOutlet var bcView: Breadcrumbs!
    @IBOutlet var activatePandoraBtn: UIButton!
    private var manager = NetworkManager.sharedInstance
    private var absoluteUrl:String!
    private var successUrl:String!
    
    var networkValidationTimer = NSTimer()
    var notification = NSNotificationCenter.defaultCenter()
    var alerts = Alerts()
    
    @IBAction func activateBtn(sender: UIButton) {
        manager.getActivationCode()
        indicator.alpha = 1.0
        indicator.startAnimating()
        activatePandoraBtn.enabled = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bcView.buildCrumbs(4)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        notification.addObserver(self, selector: "validateAddress:", name: Constants.kNetworkManagerDidRetreiveNetworkStatus, object: nil)
        notification.addObserver(self, selector: "getValidatedUrl:", name: Constants.kNetworkManagerDidReceiveActivationCode, object: nil)
        notification.addObserver(self, selector: "deviceAlreadyRegistered", name: Constants.kNetworkManagerResetPageToDefaultState, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        activatePandoraBtn.enabled = false
        indicator.startAnimating()
        manager.getNetworkStatus()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        notification.removeObserver(self)
    }
    
    
    func deviceAlreadyRegistered() {
        let title = Constants.kAlertRegisteredDeviceTitle
        let message = Constants.kAlertRegisteredDeviceMessage
        let obj = ["title":title, "message":message]
        presentViewController(alerts.showErrorAlert(obj), animated: true, completion: nil)

        resetView()
    }
    
    func resetView() {
        indicator.alpha = 0.0
        indicator.stopAnimating()
        activatePandoraBtn.enabled = true
    }
    
    func validateAddress(notification:NSNotification) {
        if let list = notification.object as? [String:AnyObject] {
            if !manager.validIPAddresses(list) {
                networkValidationTimer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: "pulseForNetworkStatus", userInfo: nil, repeats: false)
            } else {
                resetView()
            }
        }
    }
    
    func getValidatedUrl(notification: NSNotification) {
        if let response = notification.object! as? [String:AnyObject] {
            let url = response["url"] as! String
            let successCode = response["code"]! as! String
            successUrl = response["successUrl"]! as! String
            absoluteUrl = String("\(url)?activation_code=\(successCode)&success_url=\(successUrl)")
            performSegueWithIdentifier(Constants.activationSegue, sender: self)
        }
    }
        
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        var destination = segue.destinationViewController as UIViewController
        let lbl = UILabel(frame: CGRectZero)
        if let navCon = destination as? UINavigationController {
            destination = navCon.visibleViewController!
        }
        
        let attributes: [String: AnyObject] = [NSFontAttributeName: UIFont(name: lbl.getCustomFont(), size: 14)!, NSForegroundColorAttributeName: ThemeManager.currentTheme().mainColor]
        let closeBtn = UIBarButtonItem(title: "Close", style: .Done, target:self, action: "closeNavCon")
        closeBtn.setTitleTextAttributes(attributes, forState: .Normal)
        
        let backBtn = UIBarButtonItem(title: "< Back", style: .Plain, target:self, action: "barButtonBack")
        backBtn.setTitleTextAttributes(attributes, forState: .Normal)
        indicator.stopAnimating()
        activatePandoraBtn.enabled = true

        if let activateViewController = destination as? ActivatePandoraViewController {
            lbl.getCustomLabel(Constants.kConstantTitlePandoraActivation, size: 16.0)
            activateViewController.absoluteUrl = absoluteUrl
            activateViewController.successUrl = successUrl
            activateViewController.navigationItem.titleView = lbl
            activateViewController.navigationItem.rightBarButtonItem = closeBtn
            activateViewController.navigationItem.leftBarButtonItem = backBtn
        }
    }
    
    func pulseForNetworkStatus() {
        manager.getNetworkStatus()
    }
    
    func closeNavCon() {
        manager.stopSearching()
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func barButtonBack() {
        self.navigationController?.popViewControllerAnimated(true)
    }
}