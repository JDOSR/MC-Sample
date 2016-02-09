//
//  NewProfusionViewController.swift
//  MoodController
//
//  Created by Jason Owens on 12/8/15.
//  Copyright © 2015 MoodMedia. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class NewProfusionViewController : UIViewController
{
    @IBOutlet var bcView: Breadcrumbs!
    var manager = NetworkManager.sharedInstance
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bcView.buildCrumbs(0)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func continueSetup(sender: UIButton) {
        performSegueWithIdentifier(Constants.connectProfusion, sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        var destination = segue.destinationViewController as UIViewController
        let lbl = UILabel(frame: CGRectZero)
        if let navCon = destination as? UINavigationController {
            destination = navCon.visibleViewController!
        }
        if let connectViewController = destination as? ConnectViewController {
            lbl.getCustomLabel(Constants.kConstantTitleConnectToProfusion, size: 24.0)
            connectViewController.navigationItem.titleView = lbl
            connectViewController.segued = self
            //
            let attributes: [String: AnyObject] = [NSFontAttributeName: UIFont(name: lbl.getCustomFont(), size: 14)!, NSForegroundColorAttributeName: ThemeManager.currentTheme().mainColor]
            let closeBtn = UIBarButtonItem(title: "Close", style: .Done, target:self, action: "closeNavCon")
            closeBtn.setTitleTextAttributes(attributes, forState: .Normal)
            connectViewController.navigationItem.rightBarButtonItem = closeBtn
        
            let backBtn = UIBarButtonItem(title: "< Back", style: .Plain, target:self, action: "barButtonBack")
            backBtn.setTitleTextAttributes(attributes, forState: .Normal)
            connectViewController.navigationItem.leftBarButtonItem = backBtn
        }
    }

    func closeNavCon() {self.navigationController?.dismissViewControllerAnimated(true, completion: nil)}
    func barButtonBack() {self.navigationController?.popViewControllerAnimated(true)}
}