//
//  SetNameViewController.swift
//  MoodController
//
//  Created by Jason Owens on 12/11/15.
//  Copyright © 2015 MoodMedia. All rights reserved.
//

import Foundation
import UIKit

class SetNameViewController : UIViewController, UITextFieldDelegate
{

    @IBOutlet var bcView: Breadcrumbs!
    @IBOutlet weak var setNameTextField: UITextField!
    private var manager = NetworkManager.sharedInstance

    
    override func viewDidLoad() {
        super.viewDidLoad()
        bcView.buildCrumbs(2)
        setNameTextField.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let mKey = manager.userDefinedDeviceNameKey
        let cService = manager.services[manager.userDefinedDeviceNameKey]
        if cService != nil {
            if let mValue = cService! as NSNetService! {
                if  mKey != mValue {
                    setNameTextField.text! = ""
                }
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func setNameBtn(sender: UIButton) {
        if validateText(setNameTextField.text!) {
            if manager.saveAndContinue(setNameTextField.text!) {
                performSegueWithIdentifier(Constants.to_wired_segue, sender: self)
            }
        }
    }
    
    func validateText(textName: String) -> Bool {
        if textName.isEmpty || textName.characters.count < 4 {
            return false
        }
        return true
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        var destination = segue.destinationViewController as UIViewController
        let lbl = UILabel(frame: CGRectZero)
        if let navCon = destination as? UINavigationController {
            destination = navCon.visibleViewController!
        }
        if let connectViewController = destination as? WiFiOrWiredViewController {
            lbl.getCustomLabel(Constants.kConstantTitleConnectToNetwork, size: 20.0)
            connectViewController.navigationItem.titleView = lbl
            
            let attributes: [String: AnyObject] = [NSFontAttributeName: UIFont(name: lbl.getCustomFont(), size: 14)!, NSForegroundColorAttributeName: ThemeManager.currentTheme().mainColor]
            let closeBtn = UIBarButtonItem(title: "Close", style: .Done, target:self, action: "closeNavCon")
            closeBtn.setTitleTextAttributes(attributes, forState: .Normal)
            connectViewController.navigationItem.rightBarButtonItem = closeBtn
            
            let backBtn = UIBarButtonItem(title: "< Back", style: .Plain, target:self, action: "barButtonBack")
            backBtn.setTitleTextAttributes(attributes, forState: .Normal)
            connectViewController.navigationItem.leftBarButtonItem = backBtn
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if manager.saveAndContinue(textField.text!) {
            performSegueWithIdentifier(Constants.to_wired_segue, sender: self)
        }
        return true
    }
    
    func closeNavCon() {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func barButtonBack() {
        self.navigationController?.popViewControllerAnimated(true)
    }
}

extension Dictionary {
    subscript(i:Int) -> (key:Key,value:Value) {
        get {
            return self[startIndex.advancedBy(i)]
        }
    }
}