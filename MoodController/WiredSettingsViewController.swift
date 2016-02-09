//
//  WiredSettingsViewController.swift
//  MoodController
//
//  Created by Jason Owens on 12/11/15.
//  Copyright © 2015 MoodMedia. All rights reserved.
//

import Foundation
import UIKit

class WiredSettingsViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var bcView: Breadcrumbs!
    @IBOutlet var wiredSettingsTblView: UITableView!
    private var manager = NetworkManager.sharedInstance
    var notifications = NSNotificationCenter.defaultCenter()
    var selectedIndexPath = NSIndexPath()
    let validTextLength = 4
    var indicator:UIActivityIndicatorView!
    var credentials:Dictionary<String, String>!
    @IBOutlet var connectIndicator: UIImageView! {
        didSet {
            restartAnimation()
        }
    }

    var alertViewController:UIAlertController!
    var alerts = Alerts()
    
    @IBAction func continueBtn(sender: UIButton) {
        performSegueWithIdentifier(Constants.toPandoraAccount2, sender: self)
    }
    
    @IBAction func enterStaticIPBtn(sender: UIButton) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bcView.buildCrumbs(3)
        manager.clearNetworks()
        wiredSettingsTblView.delegate = self
        wiredSettingsTblView.dataSource = self
        self.credentials = Dictionary()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        notifications.addObserver(self, selector: "updateTable:", name: Constants.kNetworkManagerWillUpdateTableView, object: nil)
        notifications.addObserver(self, selector: "scanForNetworks", name: Constants.kNetworkManagerGetEditConfigurationToScan, object: nil)
        notifications.addObserver(self, selector: "saveCurrentNetworkConfiguration:", name: Constants.kNetworkManagerDidRetreiveNetworkStatus, object: nil)
        notifications.addObserver(self, selector: "showSuccessfulConfirmation", name: Constants.kNetworkManagerDidSaveConfigurationToDevice, object: nil)
        notifications.addObserver(self, selector: "showErrorAlert:", name: Constants.kNetworkManagerLoginErrorNotification, object: nil)

        wiredSettingsTblView.alpha = 0.0
        connectIndicator.alpha = 1.0
        
        restartAnimation()
        manager.configureNetworkEdit(true, toPointer: Constants.kNetworkManagerGetEditConfigurationToScan)

    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        notifications.removeObserver(self)
    }

    func scanForNetworks() {
        manager.scan()
    }
    
    func saveCurrentNetworkConfiguration(notification:NSNotification) {
        if let list = notification.object as? [String:AnyObject] {
            if !manager.validIPAddresses(list) {
                if self.credentials["essid"] == nil {
                    self.credentials["essid"] = ""
                }
                if self.credentials["password"] == nil {
                    self.credentials["password"] = ""
                }
                manager.save(list, creds: self.credentials)
            } else {
                showSuccessfulConfirmation()
            }
        }
    }

    func showSuccessfulConfirmation() {
        self.indicator.stopAnimating()
        let cell = wiredSettingsTblView.cellForRowAtIndexPath(selectedIndexPath)
        cell!.accessoryView = nil
        cell!.accessoryType = .Checkmark
    }

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
        
        if let pandoraViewController = destination as? SetUpPandoraViewController {
            lbl.getCustomLabel("Setup", size: 20.0)
            pandoraViewController.navigationItem.titleView = lbl
            pandoraViewController.navigationItem.rightBarButtonItem = closeBtn
            pandoraViewController.navigationItem.leftBarButtonItem = backBtn
        }
    }

    
    //Mark:  UITableView Delegates & DataSource Methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return manager.networks.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let tableCellIdentifier = "WiredTableCellIdentifier"
        let cell = tableView.dequeueReusableCellWithIdentifier(tableCellIdentifier, forIndexPath: indexPath) as UITableViewCell
        
        let lbl = UILabel(frame: CGRectZero)
        let network_attributes: [String: AnyObject] = [NSFontAttributeName: UIFont(name: lbl.getCustomBoldFont(), size: 16)!, NSForegroundColorAttributeName: ThemeManager.currentTheme().mainColor]
        let detail_attributes: [String: AnyObject] = [NSFontAttributeName: UIFont(name: lbl.getCustomFont(), size: 12)!, NSForegroundColorAttributeName: UIColor.grayColor()]
        
        cell.textLabel?.textAlignment = .Center
        
        let networkId = NSMutableAttributedString(string: "\(manager.networks[indexPath.row]["essid"]!) ", attributes: network_attributes)
        let securityId:NSAttributedString
        
        if manager.networks[indexPath.row]["essid"]! == manager.currentNetwork {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryView = UIView(frame: CGRectZero)
        }
        
        if manager.networks[indexPath.row]["security"]! != "" {
            securityId = NSAttributedString(string: "(\(manager.networks[indexPath.row]["security"]!))", attributes: detail_attributes)
            networkId.appendAttributedString(securityId)
        } else {
            securityId = NSAttributedString(string: "", attributes: detail_attributes)
        }
        
        cell.textLabel?.attributedText = networkId
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedIndexPath = indexPath
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        
        self.indicator = UIActivityIndicatorView(frame: CGRectZero)
        self.indicator.color = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        self.indicator.activityIndicatorViewStyle = .Gray
        self.indicator.sizeToFit()
        cell?.accessoryView = self.indicator
        self.indicator.startAnimating()
        
        if manager.networks.last! == manager.networks[indexPath.row]  {
            manager.getNetworkStatus()
        } else {
            showAlertView(manager.networks[indexPath.row]["essid"]!)
        }
    }
    
    func showErrorAlert(notification:NSNotification) {
        let obj = notification.object as? [String:AnyObject]
        presentViewController(alerts.showErrorAlert(obj!), animated: true, completion: nil)
    }
    
    func showAlertView(networkName:String) {
        alertViewController = UIAlertController(title: "Enter WiFi Password for", message: networkName, preferredStyle: .Alert)
        self.credentials["essid"] = networkName
        
        alertViewController.addTextFieldWithConfigurationHandler { [weak self] textField -> Void in
            textField.placeholder = "Password"
            textField.secureTextEntry = true
            textField.addTarget(self, action: "textFieldEditingChanged:", forControlEvents: .EditingChanged)
        }
        
        let cancelBtn = UIAlertAction(title: "Cancel", style: .Cancel) { (action) -> Void in
            self.indicator.stopAnimating()
        }
        
        let connectBtn = UIAlertAction(title: "Connect", style: .Default) { (action) -> Void in
            let loginTextField = self.alertViewController.textFields![0] as UITextField
            self.credentials["password"] = loginTextField.text!
            self.manager.getNetworkStatus()
            
        }
        connectBtn.enabled = false
        alertViewController.addAction(connectBtn)
        alertViewController.addAction(cancelBtn)
        
        presentViewController(alertViewController, animated: true, completion: nil)
    }
    
    func textFieldEditingChanged(textField:UITextField) {
        if textField.text!.characters.count > validTextLength {
            alertViewController.actions[0].enabled = true
        }
    }

    func updateTable(notification:NSNotification) {
        manager.networks.removeAll()
        
        if let list = notification.object as? Dictionary<String, AnyObject> {
            if let networks = list["networks"] as? [AnyObject] {
                for item in networks {
                    let essid = item["essid"] as! String
                    let security = item["security"] as! String
                    if (!manager.networks.contains { $0 == ["essid" : essid, "security" : security] })     {
                        manager.networks.append(["essid" : essid, "security" : security])
                    }
                }
            }
        }
        
        manager.networks.append(["essid" :"Other...", "security" : ""])
        
        if(manager.networks.count > 1) {
            wiredSettingsTblView.alpha = 1.0
            connectIndicator.alpha = 0.0
        } else {
            wiredSettingsTblView.alpha = 0.0
            connectIndicator.alpha = 1.0
        }
        wiredSettingsTblView.reloadData()
    }
    
    
    func closeNavCon() {
        manager.stopSearching()
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func barButtonBack() {
        self.navigationController?.popViewControllerAnimated(true)
    }
}