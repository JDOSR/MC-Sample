//
//  WifiOrWiredViewController.swift
//  MoodController
//
//  Created by Jason Owens on 12/11/15.
//  Copyright © 2015 MoodMedia. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class WiFiOrWiredViewController : UIViewController {
    
    @IBOutlet var bcView: Breadcrumbs!
    private var manager = NetworkManager.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        bcView.buildCrumbs(2)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func wifiSetupBtn(sender: UIButton) {
        performSegueWithIdentifier(Constants.statusSegue, sender: self)
    }
    
    @IBAction func wiredSetupBtn(sender: UIButton) {
        performSegueWithIdentifier(Constants.wiredSettingsSegue, sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        var destination = segue.destinationViewController as UIViewController
        let lbl = UILabel(frame: CGRectZero)
        if let navCon = destination as? UINavigationController {
            destination = navCon.visibleViewController!
        }
        if let identifier = segue.identifier {
            switch identifier {
                case Constants.statusSegue:
                    if let statusViewController = destination as? StatusViewController {
                        lbl.getCustomLabel("Connect to WiFi", size: 20.0)
                        statusViewController.navigationItem.titleView = lbl
                        //
                        
                        let attributes: [String: AnyObject] = [NSFontAttributeName: UIFont(name: lbl.getCustomFont(), size: 14)!, NSForegroundColorAttributeName: ThemeManager.currentTheme().mainColor]
                        let closeBtn = UIBarButtonItem(title: "Close", style: .Done, target:self, action: "closeNavCon")
                        closeBtn.setTitleTextAttributes(attributes, forState: .Normal)
                        statusViewController.navigationItem.rightBarButtonItem = closeBtn
                        
                        let backBtn = UIBarButtonItem(title: "< Back", style: .Plain, target:self, action: "barButtonBack")
                        backBtn.setTitleTextAttributes(attributes, forState: .Normal)
                        statusViewController.navigationItem.leftBarButtonItem = backBtn
                    }
                case Constants.wiredSettingsSegue:
                    if let wsViewController = destination as? WiredSettingsViewController {
                        lbl.getCustomLabel("Wired Settings", size: 20.0)
                        wsViewController.navigationItem.titleView = lbl
                        //
                        let attributes: [String: AnyObject] = [NSFontAttributeName: UIFont(name: lbl.getCustomFont(), size: 14)!, NSForegroundColorAttributeName: ThemeManager.currentTheme().mainColor]
                        let closeBtn = UIBarButtonItem(title: "Close", style: .Done, target:self, action: "closeNavCon")
                        closeBtn.setTitleTextAttributes(attributes, forState: .Normal)
                        wsViewController.navigationItem.rightBarButtonItem = closeBtn
                        
                        let backBtn = UIBarButtonItem(title: "< Back", style: .Plain, target:self, action: "barButtonBack")
                        backBtn.setTitleTextAttributes(attributes, forState: .Normal)
                        wsViewController.navigationItem.leftBarButtonItem = backBtn
                    }
                default:
                    if let _ = destination as? WiredSettingsViewController {}
            }
        }
    }
    
    func closeNavCon() {
        manager.stopSearching()
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func barButtonBack() {
        self.navigationController?.popViewControllerAnimated(true)
    }
}