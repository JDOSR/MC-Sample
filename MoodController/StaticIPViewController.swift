//
//  StaticIPViewController
//  MoodController
//
//  Created by Jason Owens on 12/11/15.
//  Copyright © 2015 MoodMedia. All rights reserved.
//

import Foundation
import UIKit

class StaticIPViewController : UIViewController
{
    
    private var manager = NetworkManager.sharedInstance
    @IBOutlet var cntToDeviceLabel: UILabel!

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

        if let connectViewController = destination as? ConnectViewController {
            lbl.getCustomLabel(Constants.kConstantTitleConnectToNetwork, size: 20.0)
            connectViewController.navigationItem.titleView = lbl
            //
            connectViewController.navigationItem.rightBarButtonItem = closeBtn
            connectViewController.navigationItem.leftBarButtonItem = backBtn
        } else if let pandoraViewController = destination as? SetUpPandoraViewController {
            
            lbl.getCustomLabel(Constants.kConstantTitleSetup, size: 20.0)
            pandoraViewController.navigationItem.titleView = lbl
            //
            pandoraViewController.navigationItem.rightBarButtonItem = closeBtn
            pandoraViewController.navigationItem.leftBarButtonItem = backBtn
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