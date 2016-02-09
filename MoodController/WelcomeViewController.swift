//
//  WelcomeViewController.swift
//  MoodController
//
//  Created by Jason Owens on 12/8/15.
//  Copyright © 2015 MoodMedia. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class WelcomeViewController : UIViewController
{
    
    private var manager = NetworkManager.sharedInstance
    var alerts = Alerts()
    @IBOutlet var setUpProBtn: UIButton! {
        didSet {
            setUpProBtn.adjustsImageWhenHighlighted = false
        }
    }
    
    @IBOutlet var existingProBtn: UIButton! {
        didSet {
            existingProBtn.adjustsImageWhenHighlighted = false
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @IBAction func setUpProfusion(sender: UIButton) {
        performSegueWithIdentifier(Constants.newPro, sender: self)
    }
    
    @IBAction func setUpExistingProfusion(sender: UIButton) {
        if manager.isServiceRenamed() {
            performSegueWithIdentifier(Constants.existPro, sender: self)
        } else {
            let title = Constants.kAlertWelcomeDevicesTitle
            let message = Constants.kAlertWelcomeDevicesMessage
            let obj = [Constants.kConstantTitleText:title, Constants.kConstantMessageText:message]
            presentViewController(alerts.showErrorAlert(obj), animated: true, completion: nil)
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        var destination = segue.destinationViewController as UIViewController
        let lbl = UILabel(frame: CGRectZero)
        let attributes: [String: AnyObject] = [NSFontAttributeName: UIFont(name: lbl.getCustomFont(), size: 14)!, NSForegroundColorAttributeName: ThemeManager.currentTheme().mainColor]
        let closeBtn = UIBarButtonItem(title: "Close", style: .Done, target: self, action: "closeNavCon")
        closeBtn.setTitleTextAttributes(attributes, forState: .Normal)

        if let navCon = destination as? UINavigationController {
            destination = navCon.visibleViewController!
        }
        if let identifier = segue.identifier {
            switch identifier {
            case Constants.newPro:
                if let newProViewController = destination as? NewProfusionViewController {
                    lbl.getCustomLabel(Constants.kConstantTitleLetsGetStarted, size: 24.0)
                    newProViewController.navigationItem.titleView = lbl
                    newProViewController.navigationItem.rightBarButtonItem = closeBtn
                }
                break
            case Constants.existPro:
                if let connectViewController = destination as? ConnectViewController {
                    lbl.getCustomLabel(Constants.kConstantTitleNameYourProfusion, size: 24.0)
                    connectViewController.navigationItem.titleView = lbl
                    connectViewController.segued = self
                    connectViewController.navigationItem.rightBarButtonItem = closeBtn
                }
                break
            default:
                NSLog("Whatever", "")
            }
        }
    }
    
    func closeNavCon() {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}