//
//  ActivatePandoraViewController.swift
//  MoodController
//
//  Created by Jason Owens on 12/11/15.
//  Copyright © 2015 MoodMedia. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class ActivatePandoraViewController : UIViewController, WKNavigationDelegate, WKUIDelegate {

    @IBOutlet var bcView: Breadcrumbs!
    var webView:WKWebView!
    var absoluteUrl:String = ""
    var successUrl:String = ""
    var activation_timer = NSTimer()
    var notification = NSNotificationCenter.defaultCenter()
    var alerts = Alerts()

    private var manager = NetworkManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bcView.buildCrumbs(4)
        let yPos = CGFloat(110.0)
        let height = UIScreen.mainScreen().bounds.height - yPos
        let webViewFrame = CGRectMake(0.0, yPos, UIScreen.mainScreen().bounds.width, height)
        let configuration = WKWebViewConfiguration()
        webView = WKWebView(frame: webViewFrame, configuration: configuration)
        webView.navigationDelegate = self
        webView.UIDelegate = self
        self.view.addSubview(webView)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        notification.addObserver(self, selector: "checkForActivation:", name: Constants.kNetworkManagerDidRequestToActivate, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let url = NSURL(string: absoluteUrl)
        let urlRequest = NSURLRequest(URL: url!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 60.0)
        webView.loadRequest(urlRequest)
        manager.activate()
    }
    

    func checkForActivation(notification:NSNotification) {
        if let response = notification.object as? [String:AnyObject] {
            if let isActive = response["active"] as? Bool {
                if isActive {
                    print("Is Active: \(isActive)")
                    activation_timer.invalidate()
                    bcView.updateBreadcrumb(4)
                    let obj = [Constants.kConstantTitleText:"Success!", Constants.kConstantMessageText:response["message"]!]
                    presentViewController(alerts.showErrorAlert(obj), animated: true, completion: nil)
                }
            } else {
                print("Is Not Active: \(response["active"])")
                if !activation_timer.valid {
                    activation_timer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: manager, selector: "activate", userInfo: nil, repeats: true)
                }
            }
        }
    }
    
    //UIDelegate Methods
    func webView(webView: WKWebView, createWebViewWithConfiguration configuration: WKWebViewConfiguration, forNavigationAction navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        print("webView: createWebViewWithConfiguration configuration: \(configuration), forNavigationAction navigationAction: \(navigationAction), windowFeatures: \(windowFeatures)")
            return webView
    }
    
    func webView(webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: () -> Void) {
            print("webView: runJavaScriptAlertPanelWithMessage message: \(message), forNavigationAction initiatedByFrame: \(frame)")
    }
    
    func webView(webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: (Bool) -> Void) {
        print("webView: runJavaScriptConfirmPanelWithMessage message: \(message), initiatedByFrame: \(frame)")
    }
    
    func webView(webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: (String?) -> Void) {
        print("webView: runJavaScriptTextInputPanelWithPrompt prompt: \(prompt), defaultText: \(defaultText), initiatedByFrame \(frame)")
    }


    //NavigationDelegate Methods
    func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
        print("webView: didCommitNavigation navigation: \(navigation.description)!")
    }

    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        print("webView: didFinishNavigation navigation: \(navigation.description)!")
    }

    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        print("webView: didFailNavigation navigation: \(navigation)!, withError error: \(error)")
    }


    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("webView: didStartProvisionalNavigation webUrl: \(webView.URL!)")
    }

    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        print("webView: didFailProvisionalNavigation navigation: \(navigation)!, withError error: \(error)")
    }
    

    func webView(webView: WKWebView, didReceiveAuthenticationChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {

        let aMethod = challenge.protectionSpace
        if aMethod.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            let trust:SecTrustRef = aMethod.serverTrust!
            let newTrustPolicies = NSMutableArray(capacity: 1)
            let certificates = NSMutableArray(capacity: 1)
            var newTrust:SecTrustRef?
            let updatedHost = manager.host.substringToIndex(manager.host.endIndex.predecessor()).lowercaseString
            let policyRef = SecPolicyCreateSSL(true, updatedHost)
//            print("Certificate Host: \(updatedHost)")
            newTrustPolicies.addObject(policyRef)
            
            let count = SecTrustGetCertificateCount(trust)
            for i in 0..<count {
                let item:SecCertificateRef = SecTrustGetCertificateAtIndex(trust, i)!
                certificates.addObject(item)
            }
            
            if SecTrustCreateWithCertificates(certificates, newTrustPolicies, &newTrust) != errSecSuccess {
                print("\(newTrust) was not created")
            }
            
            if SecTrustSetAnchorCertificates(newTrust!, certificates) != errSecSuccess {
                print("\(certificates) anchors were not set")
            }
            
            let certResultType = UnsafeMutablePointer<SecTrustResultType>.alloc(sizeof(SecTrustResultType) * 32)
            let status = SecTrustEvaluate(newTrust!, certResultType)
            if status != errSecSuccess {
                print("Failed: \(SecTrustCopyResult(newTrust!))\n\(SecTrustCopyProperties(newTrust!))")
                challenge.sender?.cancelAuthenticationChallenge(challenge)
                completionHandler(.CancelAuthenticationChallenge, nil)
                webView.stopLoading()
                return
            }
            
            let credential = NSURLCredential(trust: newTrust!)
            switch  certResultType[0] {
                case SecTrustResultType(kSecTrustResultUnspecified), SecTrustResultType(kSecTrustResultProceed):
                    challenge.sender?.useCredential(credential, forAuthenticationChallenge: challenge)
                    completionHandler(.UseCredential, credential)

                case SecTrustResultType(kSecTrustResultRecoverableTrustFailure):
                    print("kSecTrustResultRecoverableTrustFailure")
                case SecTrustResultType(kSecTrustResultFatalTrustFailure):
                    print("kSecTrustResultFatalTrustFailure")
                case SecTrustResultType(kSecTrustResultOtherError):
                    print("kSecTrustResultOtherError")
                default:
                    print("kSecTrustResultInvalid")
                    /* It's somebody else's key. Fall through. */
            }
            /* The server sent a key other than the trusted key. */
        }
        challenge.sender?.continueWithoutCredentialForAuthenticationChallenge(challenge)
        print("webView: didReceiveAuthenticationChallenge challenge: \(challenge)")
    }
    
    func webView(webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print("webView: didReceiveServerRedirectForProvisionalNavigation navigation: \(webView.URL!)")
    }
    
    
    //Deciding Load Policy
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        
        let secureHTTPPrefix = "https://"
        let range = Range(start: secureHTTPPrefix.startIndex, end: secureHTTPPrefix.endIndex)
        let header = webView.URL?.absoluteString.substringWithRange(range)
        if header == secureHTTPPrefix {
            dispatch_async(dispatch_get_main_queue(), {
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.kNetworkManagerDidRequestToActivate, object:nil)
            })
        }
        decisionHandler(.Allow)
//        print("webView: \(webView.URL!), decidePolicyForNavigationAction navigationAction:")
    }
    
    func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.Allow)
//        print("webView: \(webView), decidePolicyForNavigationResponse navigationResponse: \(navigationResponse)")
    }
    
    func closeNavCon() {
        manager.stopSearching()
        activation_timer.invalidate()
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func barButtonBack() {
        activation_timer.invalidate()
        self.navigationController?.popViewControllerAnimated(true)
    }


}