//
//  ConnectViewController.swift
//  MoodController
//
//  Created by Jason Owens on 12/8/15.
//  Copyright © 2015 MoodMedia. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore



@IBDesignable
class ConnectViewController : UIViewController, UITableViewDelegate, UITableViewDataSource
{    
    @IBOutlet var bcView: Breadcrumbs!
    private var manager = NetworkManager.sharedInstance
    var selectedRow:Int =  0
    var indicator:UIActivityIndicatorView!
    var alerts = Alerts()
    
    @IBAction func wifiSettings(sender: UIButton) {
        presentViewController(alerts.showSettingsAppAlertView(), animated: true, completion: nil)

    }
    @IBOutlet var connectIndicator: UIImageView! {
        didSet {
            restartAnimation()
        }
    }
    var segued:UIViewController?
    @IBOutlet var cntTableView: UITableView!
    var notifications = NSNotificationCenter.defaultCenter()
    
    
    func restartAnimation() {
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.toValue = CGFloat(M_PI * 2.0) * 5.0
        animation.duration = 5.0
        animation.cumulative = true
        animation.repeatCount = 100.0
        animation.delegate = self
        connectIndicator.layer.anchorPoint = CGPoint(x: 0.50, y: 0.475)
        connectIndicator.layer.addAnimation(animation, forKey: "transform.rotation.z")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cntTableView.delegate = self
        cntTableView.dataSource = self
        cntTableView.alpha = 0.0
        bcView.buildCrumbs(1)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        notifications.addObserver(self, selector: "updateTable", name: Constants.kNetworkManagerWillUpdateTableView, object: nil)
        notifications.addObserver(self, selector: "saveToSetNameController", name: Constants.kNetworkManagerDidLogUserIn, object: nil)
        notifications.addObserver(self, selector: "showErrorAlert:", name: Constants.kNetworkManagerNetServiceErrorDidNotResolve, object: nil)
        notifications.addObserver(self, selector: "showErrorAlert:", name: Constants.kNetworkManagerLoginErrorNotification, object: nil)
        notifications.addObserver(self, selector: "stopSearching", name: Constants.kNetworkManagerStopSearchingForServices, object: nil)
        notifications.addObserver(self, selector: "startSearching", name: Constants.kNetworkManagerStopSearchingForServices, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if segued!.isKindOfClass(NewProfusionViewController) {
            manager.startSearching()
        } else if segued!.isKindOfClass(WelcomeViewController) {
            for (key, value) in manager.services {
                if value!.name == key  {
                    manager.services.removeValueForKey(key)
                }
            }
            if manager.services.count > 0 {
                updateTable()
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        notifications.removeObserver(self)
    }
    
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        restartAnimation()
    }
    
    func stopSearching() {
        manager.stopSearching()
        
    }
    func startSearching() {
        manager.startSearching()
    }
        
    func showErrorAlert(notification:NSNotification) {
        let object = notification.object as? [String:AnyObject]
        presentViewController(alerts.showErrorAlert(object!), animated: true, completion: nil)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        var destination = segue.destinationViewController as UIViewController
        let lbl = UILabel(frame: CGRectZero)
        if let navCon = destination as? UINavigationController {
            destination = navCon.visibleViewController!
        }
        
        if let sameNameViewController = destination as? SetNameViewController {
            lbl.getCustomLabel(Constants.kConstantTitleNameYourProfusion, size: 24.0)
            sameNameViewController.navigationItem.titleView = lbl
            //

            let attributes: [String: AnyObject] = [NSFontAttributeName: UIFont(name: lbl.getCustomFont(), size: 14)!, NSForegroundColorAttributeName: ThemeManager.currentTheme().mainColor]
            let closeBtn = UIBarButtonItem(title: "Close", style: .Done, target:self, action: "closeNavCon")
            closeBtn.setTitleTextAttributes(attributes, forState: .Normal)
            sameNameViewController.navigationItem.rightBarButtonItem = closeBtn
            
            let backBtn = UIBarButtonItem(title: "< Back", style: .Plain, target:self, action: "barButtonBack")
            backBtn.setTitleTextAttributes(attributes, forState: .Normal)
            sameNameViewController.navigationItem.leftBarButtonItem = backBtn
        }
    }
    
    //Mark:  UITableView Delegates & DataSource Methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return manager.services.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let tableCellIdentifier = "UniqueTableCellIdentifier"
        
        let cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier(tableCellIdentifier)! as UITableViewCell
        
        let lbl = UILabel(frame: CGRectZero)
        let attributes: [String: AnyObject] = [NSFontAttributeName: UIFont(name: lbl.getCustomFont(), size: 16)!, NSForegroundColorAttributeName: ThemeManager.currentTheme().mainColor]
        cell.textLabel?.textAlignment = .Center
        let serviceName = Array(manager.services.keys)[indexPath.row]
        cell.textLabel?.attributedText = NSAttributedString(string: serviceName, attributes: attributes)
        cell.accessoryView = UIView(frame: CGRectZero)
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        self.indicator = UIActivityIndicatorView(frame: CGRectZero)
        self.indicator.color = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        self.indicator.activityIndicatorViewStyle = .Gray
        self.indicator.sizeToFit()
        cell?.accessoryView = self.indicator
        self.indicator.startAnimating()
        
        if manager.userDefinedDeviceNameKey == "userDefinedDeviceNameKey" {
            manager.userDefinedDeviceNameKey = (cell?.textLabel?.text)!
        }
        
        self.selectedRow = indexPath.row
        manager.resolveService()
    }
    
    func updateTable() {
        cntTableView.reloadData()
        if(manager.services.count > 0) {
            cntTableView.alpha = 1.0
            connectIndicator.alpha = 0.0
        } else {
            cntTableView.alpha = 0.0
            connectIndicator.alpha = 1.0
        }
    }
    
    func saveToSetNameController() {
        if self.indicator != nil && self.indicator.isAnimating() {
            self.indicator.stopAnimating()
        }
        performSegueWithIdentifier(Constants.set_name_segue, sender: self)
    }
    
    func closeNavCon() {
        manager.stopSearching()
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    func barButtonBack() {
        self.navigationController?.popViewControllerAnimated(true)
    }
}