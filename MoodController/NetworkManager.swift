//
//  NetworkManager.swift
//  MoodController
//
//  Created by Jason Owens on 12/17/15.
//  Copyright © 2015 MoodMedia. All rights reserved.
//
//Test Device ID: 399398

import Foundation
import SystemConfiguration
import NetworkExtension
import UIKit
import Security

enum EncryptionError : ErrorType {
    case Empty
    case Short
}

enum NetworkUrl {
    case Login, Logout, Status, Edit, isEditing, Scan, Save, Info, Cancel, Activate, Start, Stop, Unknown, API
    case GetActivationCode, Default, GetZoneList, GetZoneStatus
    
    func url() -> String {
        var zPath:String = ""
        switch self {
            case .Login:
                zPath = "/login"
            case .Logout:
                zPath = "/logout"
            case .Status:
                zPath = "/api/v1/config/network/getStatus"
            case .Edit:
                zPath = "/api/v1/config/network/edit"
            case .isEditing:
                zPath = "/api/v1/config/network/isEditing"
            case .Scan:
                zPath = "/api/v1/config/network/scan"
            case .Save:
                zPath = "/api/v1/config/network/save"
            case .Info:
                zPath = "/api/v1/config/getInfo"
            case .Cancel:
                zPath = "/api/v1/config/network/cancel"
            case .Activate:
                zPath = "/api/v1/zone/device/activate"
            case .Start:
                zPath = "/api/v1/device/ism/start"
            case .Stop:
                zPath = "/api/v1/device/ism/stop"
            case .GetActivationCode:
                zPath = "/api/v1/zone/device/getActivationCode"
            case .GetZoneList:
                zPath = "/api/v1/zone/getList"
            case .GetZoneStatus:
                zPath = "/api/v1/zone/getStatus"
            case .API:
                zPath = "/public/apidocs"
            case .Unknown: fatalError("This option is unavailable")
            default: break
        }
        return zPath
    }
}

class NetworkManager : NSObject, NSNetServiceDelegate, NSNetServiceBrowserDelegate,
    NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate
{
    //MARK: Instantiators
    
    class var sharedInstance:NetworkManager {
        struct Singleton {
            static let instance = NetworkManager()
        }
        return Singleton.instance
    }
    
    var host = "www.google.com"
    var IP = "10.219.4.194"
    var wifiIP = ""
    var currentUrl:NetworkUrl?
    var currentNetwork:String = ""
    let okCode = "OK"
    let ipType = "STATIC"
    var port = 0
    var notificationName = ""
    var responseObj = [String : AnyObject]()//JSON object returned
    var networks = [[String:String]]()
    var protocols = ["_http._tcp."]
    var userDefinedDeviceNameKey = "userDefinedDeviceNameKey"
    var deviceSettings = [String:AnyObject]()
    //Connection Options
    var browser:NSNetServiceBrowser!
    var ns:NSNetService!
    var hotspotHelper:NEHotspotHelper?
    var session = NSURLSession.sharedSession()
    var configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
    var input:NSInputStream?
    var output:NSOutputStream?
    var operationId:Int?
    var xSecretKey : String {
        return "1234567890"
    }
    var prod_token : String {
        let token = "aTcjMU5rNDNpVzRzOGU3VDNyN0g0bilNeDROKW0wb0Q="
        //Decoded String
        let decodedData = NSData(base64EncodedString: token, options: NSDataBase64DecodingOptions(rawValue: 0))
        return String(data: decodedData!, encoding: NSUTF8StringEncoding)!
    }
    var services = [String : NSNetService?]() as Dictionary {
        willSet {}
        didSet {}
    }
    var dateFormat:NSDateFormatter {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        return formatter
    }
    
    //MARK: Function Setup
    required override init() {
        operationId = 0
        super.init()
    }
        
    func clearNetworks() {
        if self.networks.count > 0 {
            self.networks.removeAll()
        }
    }
    
    func login() {send("POST", path: .Login, parameters: ["user":"admin", "password":"23646"], pointer:Constants.kNetworkManagerDidLogUserIn)}
    func getNetworkStatus() {send("GET", path: .Status, parameters: [:], pointer:Constants.kNetworkManagerDidRetreiveNetworkStatus)}
    func stopISMService() {send("GET", path:.Stop, parameters: [:], pointer: Constants.kNetworkManagerDidStopISMService)}
    func isEditing() {send("GET", path:.isEditing, parameters: [:], pointer:Constants.kNetworkManagerHasEditLock)}
    
    func configureNetworkEdit(force: Bool, toPointer:String) {send("GET", path: .Edit, parameters: ["force":(force ? "true" : "false")], pointer:toPointer)}
    
    func scan() {send("POST", path: .Scan, parameters:["device":"ra0"], pointer:Constants.kNetworkManagerWillUpdateTableView)}
    func save(items:[String:AnyObject], creds:Dictionary<String, String>) {
        let encodedPassword = creds["password"]!.stringByAddingPercentEncodingWithAllowedCharacters(.URLPasswordAllowedCharacterSet())
        
        if let ra = items["ra0"] as? [String : AnyObject] {
            deviceSettings["ra0Enabled"] = "true" // -- Default: 1
            deviceSettings["ra0WirelessEssid"] = creds["essid"]! //creds["essid"]! //-- Default: ""
            deviceSettings["ra0WirelessSecurity"] = "WPA2" // -- Default: "WPA2"
            deviceSettings["ra0WirelessPassword"] = encodedPassword // -- Default: ""
            deviceSettings["webUiBroadcast"] = "true" //items["webui"]!["broadcast"]!!
            
            if let ip = ra["ip"] as? [String :AnyObject] {
                deviceSettings["ra0IpType"] = ip["type"]! // -- Default: DHCP
                
                if ip["type"] as? String == ipType { //Static
                    deviceSettings["ra0IpAddress"] = ip["address"] // -- Default: ""
                    deviceSettings["ra0IpNetMask"] = ip["netMask"] // -- Default: ""
                    deviceSettings["ra0IpGateway"] = ip["gateway"] // -- Default: ""
                    if let dns = ip["dns"] as? [String : AnyObject] {
                        deviceSettings["ra0IpDnsPrimary"] = dns["primary"] // -- Default: "0.0.0.0"
                        deviceSettings["ra0IpDnsSecondary"] = dns["secondary"] // -- Default: "0.0.0.0"
                    }
                }
            }
        }

        send("POST", path:.Save, parameters: deviceSettings, pointer:Constants.kNetworkManagerDidSaveConfigurationToDevice)
    }
    
    func info() {send("GET", path: .Info, parameters:[:], pointer:"")}
    func cancel() {send("POST", path: .Cancel, parameters:[:], pointer:"")}
    func activate() {
        print("Checking for Activation:...")
        send("GET", path: .Activate, parameters:[:], pointer:Constants.kNetworkManagerDidRequestToActivate)}
    func getZoneList() {send("GET", path: .GetZoneList, parameters:[:], pointer:"")}
    func getZoneStatus(zoneId:String) {send("POST", path: .GetZoneStatus, parameters:["zoneId":zoneId], pointer:"")}

    func start() {send("POST", path: .Start, parameters:[:], pointer:"")}
    func stop() {send("POST", path: .Stop, parameters:[:], pointer:"")}
    func getActivationCode() {
        send("GET", path: .GetActivationCode, parameters:[:], pointer:Constants.kNetworkManagerDidReceiveActivationCode)
    }
    func logout() {send("GET", path: .Logout, parameters:[:], pointer:Constants.kNetworkManagerDidLogUserOut) }
    
    //MARK: Profusion API Request/Response Methods
    func send(method:String, path:NetworkUrl, parameters: NSDictionary, pointer:String) {
        //HttpMethod
        var dataToSign = method
        var data = "", tmp = "",  urlEncoded = ""
        var encodedString = NSData()
        
        //Host
        dataToSign += String("\n\(IP)")
        
        //Urlencode
        for(key, item) in parameters {
            let keyString = String(key)
            if !keyString.isEmpty  {
                data += "\(keyString)=\(item)&"
            }
        }
        
        if data.characters.count > 0 && data.characters.last! == "&" {
            data = data.substringToIndex(data.endIndex.predecessor())
        }

        //Url
        currentUrl = path
        if method == "GET" && data.characters.count > 0  {
            tmp = String("\n\(path.url())?\(data.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!)")
        } else {
            tmp = String("\n\(path.url())")
        }
        urlEncoded = tmp.removeCarriageReturn()
        dataToSign += tmp
        
        //AuthDate
        let date = NSDate()
        let dateString = dateFormat.stringFromDate(date)
        dataToSign += String("\n\(dateString)")
        
        //PayloadCheckSum - works
        if method == "POST" && data.characters.count > 0  {
            encodedString = data.dataUsingEncoding(NSASCIIStringEncoding)!
            let checksum = String(crc32(0, UnsafePointer<UInt8>(encodedString.bytes), uInt(encodedString.length)) & 0xffffffff)
            dataToSign += String("\n\(checksum)")
        }

        if path.url() != "/login" {
            let sessionid = NSUserDefaults.standardUserDefaults().objectForKey(Constants.kProductsessionIdKey)
            dataToSign += ("\n\(sessionid!)");
        }
        
        let token:String!
        let url:NSURL!
        let urlRequest:NSMutableURLRequest!
        
        configuration.HTTPCookieAcceptPolicy = .Always
        configuration.TLSMinimumSupportedProtocol = .TLSProtocol11

        if path != .Default {
            token = dataToSign.hmac(HMACAlgorithm.SHA256, key:prod_token)
            url = NSURL(string: String("https://\(IP)\(urlEncoded)"))
            urlRequest = NSMutableURLRequest(URL: url!)
            urlRequest!.HTTPMethod = method
            urlRequest!.HTTPBody = encodedString
            
            configuration.HTTPAdditionalHeaders = [
                "Content-Type"  : "application/x-www-form-urlencoded",
                "Accept" : "application/json",
                "X-AUTH-Date"   : String("\(dateString)"),
                "Authorization" : String("HMAC-SHA256 token=\(token)")]
        } else {
            url = NSURL(string: parameters.objectForKey("url") as! String)
            urlRequest = NSMutableURLRequest(URL:url!)
            urlRequest!.HTTPMethod = method
            
            configuration.HTTPAdditionalHeaders = [
                "Content-Type"  : "application/x-www-form-urlencoded",
                "Accept" : "application/json"]
        }
        
        session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        let task:NSURLSessionTask = session.dataTaskWithRequest(urlRequest, completionHandler : {(data, response, error) in
            if(error != nil) {
                self.handleError(error!, pointer: pointer)
                dispatch_async(dispatch_get_main_queue(), {
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.kNetworkManagerResetPageToDefaultState, object:nil)
                })
            } else if (data != nil && response != nil) {
                self.addCookies(response)
                if path != .Default {
                    self.jsonResponse(data!, pointer: pointer)
                } else {
                    self.htmlResponse(data!, pointer: pointer)
                }
            }
        })
        task.resume()
        print("DataToSign: \(dataToSign), url:\(urlRequest)")
    }
    
    func jsonResponse(data:NSData, pointer:String) {
        do {
            if let json = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as? [String : AnyObject] {
                if let status = json["status"] as? [String : AnyObject] {
                    if let code = status["code"] as? String {
                        if code == "OK" {
                            self.operationId = status["operationId"] as? Int
                            if let returnedObj = json["data"] as? [String : AnyObject] {
                                print("Data Response: \(returnedObj)")
                                if pointer != "" {
                                    dispatch_async(dispatch_get_main_queue(), {
                                        print("Go to: \(pointer)")
                                        NSNotificationCenter.defaultCenter().postNotificationName(pointer, object:returnedObj)
                                    })
                                } else {
                                    print("Error: Pointer must be populated with a value")
                                }
                            }
                        } else if code == "LOCKED" {
                            print("User does not have a write lock on this device")
                        } else if code == "FAILURE" {
                            self.dumpResponse(json)
                            dispatch_async(dispatch_get_main_queue(), {
                                NSNotificationCenter.defaultCenter().postNotificationName(Constants.kNetworkManagerResetPageToDefaultState, object:json["status"])
                            })
                        }
                    } else {
                        //Message to User
                    }
                }
            }
        } catch let error as NSError {
            self.handleError(error, pointer: pointer)
        }
    }
    
    func htmlResponse(data:NSData, pointer:String) {
        let html = String(data:data, encoding:NSUTF8StringEncoding)!
        print(html)
        dispatch_async(dispatch_get_main_queue(), {
            print("Go to: \(pointer)")
            NSNotificationCenter.defaultCenter().postNotificationName(pointer, object:nil)
        })
    }
    
    func addCookies(response:NSURLResponse?) {
        let cookie = NSUserDefaults.standardUserDefaults().objectForKey(Constants.kProductsessionIdKey)
        if (cookie == nil) {
            let foundCookies:[NSHTTPCookie]
            let httpResponse = (response as? NSHTTPURLResponse)!
            if let responseHeaders = httpResponse.allHeaderFields as? [String : String] {
                foundCookies = NSHTTPCookie.cookiesWithResponseHeaderFields(responseHeaders, forURL: httpResponse.URL!)
            } else {
                foundCookies = []
            }
            var result:[String:NSHTTPCookie] = [:]
            for cookie in foundCookies {
                result[cookie.name] = cookie
                if cookie.name == "sessionId" {
                    print(cookie.value)
                    NSUserDefaults.standardUserDefaults().setObject(cookie.value, forKey: Constants.kProductsessionIdKey)
                    NSUserDefaults.standardUserDefaults().synchronize()
                }
            }
        }
    }
    
    func handleError(error: NSError, pointer: String) {
        var title:String = ""
        var message:String = ""
        var obj:[String:AnyObject]
        
        switch error.code {
            case 3840 where pointer == Constants.kNetworkManagerDidLogUserIn:
                title = Constants.kAlertTitleCheckDevice
                message = Constants.kAlertMessageCheckDevice
                obj = [Constants.kConstantTitleText:title,
                    Constants.kConstantMessageText:message]
                break
            default:
                title = "Error Code: \(error.code)"
                message = "\(error.localizedDescription)"
                obj = [Constants.kConstantTitleText:title,
                    Constants.kConstantMessageText:message]
                break
        }
        dispatch_async(dispatch_get_main_queue(), {
            NSNotificationCenter.defaultCenter().postNotificationName(Constants.kNetworkManagerLoginErrorNotification, object:obj)
        })
//        print("Code: \(error.code), Domain: \(error.domain), UserInfo: \(error.userInfo)")
    }

    func startSearching() {
        
        if browser != nil {
            browser.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
            print("removedFromRunLoop")
        }
        
        let app = AppDelegate()
        
        print("start searching....")
        for hotspotNetwork in app.globalNetworkList {
            let ssid = hotspotNetwork.SSID;
            let bssid = hotspotNetwork.BSSID;
            let secure = hotspotNetwork.secure;
            let autoJoined = hotspotNetwork.autoJoined;
            let signalStrength = hotspotNetwork.signalStrength;
            print("SSID: \(ssid), BSSID: \(bssid), SECURE: \(secure), AUTOJOINED: \(autoJoined), SIGNAL_STRENGTH: \(signalStrength)")
        }
        

        for type in protocols {
            browser = NSNetServiceBrowser()
            browser.includesPeerToPeer = true
            browser.delegate = self
            browser.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
            browser.searchForServicesOfType(type, inDomain: "")
        }
    }
    
    func validIPAddresses(config:[String:AnyObject]) -> Bool {
        if let ra0 = config["ra0"] as? [String : AnyObject] {
            //Set the latest network
            if let wireless = ra0["wireless"] as? [String : AnyObject] {
                if let essid = wireless["essid"] as? String {
                    if self.currentNetwork != essid {
                        self.currentNetwork = essid
                    }
                }
            }

            if ra0["enabled"] as? String == "0" {
                return false
            }
            
            if let ip = ra0["ip"] as? [String : AnyObject] {
                if ip["address"] as? String == "0.0.0.0" ||
                ip["address"] as? String == "" ||
                    ip["address"] as? String == Constants.kConstantTextUnavailable {
                        return false
                }
                if ip["gateway"] as? String == "0.0.0.0" ||
                    ip["gateway"] as? String == "" ||
                    ip["gateway"] as? String == Constants.kConstantTextUnavailable {
                        return false
                }
                if ip["netMask"] as? String == "0.0.0.0" ||
                    ip["netMask"] as? String == "" ||
                    ip["netMask"] as? String == Constants.kConstantTextUnavailable {
                        return false
                }
                
                print("IP: \(ip["address"]!)")
                wifiIP = ip["address"]! as! String
            }
        }
        return true
    }
    
    func stopSearching () {
        browser.stop()
    }
    
    func resolveService() {
        if let ns = self.services[userDefinedDeviceNameKey] {
            ns!.delegate = self
            ns!.resolveWithTimeout(15.0)
        }
    }
    
    func connectToDevice() {
        browser.stop()
        let sessionid = NSUserDefaults.standardUserDefaults().objectForKey(Constants.kProductsessionIdKey)
        if sessionid == nil {
            login()
        } else {
            dispatch_async(dispatch_get_main_queue(), {
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.kNetworkManagerDidLogUserIn, object:nil)
            })
        }
    }
    
    func getDeviceKeyName(serviceName:String) -> String {
        for (key, value) in self.services {
            let deviceValue = (value as NSNetService!).name
            if deviceValue == serviceName {
                return key
            }
        }
        return serviceName
    }
    
    func isServiceSaved(name:String) -> Bool {
        for (_, value) in self.services {
            let serv = value as NSNetService!
            if (serv.name == name) {
                return true
            }
        }
        return false
    }
    
    func isServiceRenamed() -> Bool {
        for (key, value) in self.services {
            let keyName = key as String!
            if (keyName != value!.name) {
                return true
            }
        }
        return false
    }
    
    func saveAndContinue(text:String) -> Bool {
        let keyValue = self.services[userDefinedDeviceNameKey]
        self.services.removeValueForKey(userDefinedDeviceNameKey)
        self.services[text] = keyValue
        userDefinedDeviceNameKey = text
        return true
    }
    
    //MARK: NSURLSessionTaskDelegate Delegates
    func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) {
            let newRequest : NSURLRequest? = request
            print(newRequest?.description)
            completionHandler(newRequest)
            print("session: \(session), task: \(task), willPerformHTTPRedirection \(response), newRequest request: \(newRequest)")
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        
        let aMethod = challenge.protectionSpace
        /*****
            Technical Note TN2232 : HTTPS Server Trust Evaluation
            https://developer.apple.com/library/ios/technotes/tn2232/_index.html#//apple_ref/doc/uid/DTS40012884-CH1-SECNSURLSESSION
            also Reference: 
            http://stackoverflow.com/questions/17141226/create-ssl-connection-using-certificate
        
            https://developer.apple.com/library/mac/documentation/NetworkingInternet/Conceptual/NetworkingTopics/Articles/OverridingSSLChainValidationCorrectly.html
        *****/
        
        if aMethod.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            let trust:SecTrustRef = aMethod.serverTrust!
            let newTrustPolicies = NSMutableArray(capacity: 1)
            let certificates = NSMutableArray(capacity: 1)
            var newTrust:SecTrustRef?
            let policyRef = SecPolicyCreateSSL(true, host)
        
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
                task.cancel()
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
//        challenge.sender?.continueWithoutCredentialForAuthenticationChallenge(challenge)
        print("session: \(session), task: \(task), didReceiveChallenge \(challenge) completionHandler)")
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, needNewBodyStream completionHandler: (NSInputStream?) -> Void) {
        print("session: \(session), task: \(task), needNewBodyStream")
    }

    func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        print("session: \(session), task: \(task), didSendBodyData \(bytesSent), totalBytesSent: \(totalBytesSent), totalBytesExpectedToSend: \(totalBytesExpectedToSend)")
    }

    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        print("session: \(session), task: \(task), didCompleteWithError error: \(error)")
    }
    
    //MARK: NSURLSession Delegates
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        print("session: \(session), didBecomeInvalidWithError error: \(error?.description)")
    }
        
    //MARK: NetServiceBrowser Delegates
    func netServiceBrowserWillSearch(browser: NSNetServiceBrowser) {
        print("netServiceBrowserWillSearch... \(browser.description)")
    }
    
    func netServiceBrowserDidStopSearch(browser: NSNetServiceBrowser) {
        print("netServiceBrowserDidStopSearch...")
    }
    
    func netServiceBrowser(browser: NSNetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        let title = Constants.kAlertTitleNetServiceDidNotSearch
        let message = errorDict.debugDescription
        let obj = [Constants.kConstantTitleText:title,
            Constants.kConstantMessageText:message]
        
        dispatch_async(dispatch_get_main_queue(), {
            NSNotificationCenter.defaultCenter().postNotificationName(Constants.kNetworkManagerLoginErrorNotification, object:obj)
        })

        print("netServiceBrowser didNotSearch... error: NSNetServicesErrorDomain: \(errorDict["NSNetServicesErrorDomain"])\nNSNetServicesErrorCode:\(errorDict["NSNetServicesErrorCode"])")
    }

    func netServiceBrowser(browser: NSNetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {
        print("netServiceBrowser didFindDomain...\(domainString)")
    }
    
    func netServiceBrowser(browser: NSNetServiceBrowser, didFindService service: NSNetService, moreComing: Bool) {
        print("netServiceBrowser:didFindService: -> TYPE:\(service.type), -> NAME:\(service.name), -> DOMAIN:\(service.domain), morecoming: \(moreComing)")
        
        if (service.name.rangeOfString(Constants.deviceName, options: .CaseInsensitiveSearch) != nil) {
            if !isServiceSaved(service.name) {
                self.services[service.name] = service
            }
        } else {
            print("remove unwanted service: \(service.name)")
            netServiceBrowser(browser, didRemoveService:service, moreComing:false)
        }
        if(!moreComing && self.services.count > 0) {
            dispatch_async(dispatch_get_main_queue(), {
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.kNetworkManagerWillUpdateTableView, object:nil)
            })
        }
    }
    
    func netServiceBrowser(browser: NSNetServiceBrowser, didRemoveDomain domainString: String, moreComing: Bool) {
        print("netServiceBrowser didRemoveDomain: \(domainString) morecoming: \(moreComing)")
    }
    
    func netServiceBrowser(browser: NSNetServiceBrowser, didRemoveService service: NSNetService, moreComing: Bool) {
        print("netServiceBrowser didRemoveService: \(service.name) morecoming: \(moreComing)")
        if (service.name.rangeOfString(Constants.deviceName, options: .CaseInsensitiveSearch) != nil) {
            self.services.removeValueForKey(service.name)
            if(!moreComing && self.services.count > 0) {
                dispatch_async(dispatch_get_main_queue(), {
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.kNetworkManagerWillUpdateTableView, object:nil)
                })
            }
        }
    }
    
    //MARK: NetService Delegates
    func netServiceWillResolve(sender: NSNetService) {
        print("netServiceWillResolve:  \(sender.name)")
    }
    
    func netServiceDidResolveAddress(sender: NSNetService) {
        print("netServiceDidResolve:  \(sender.hostName!), \(sender.port), \(sender.name)")

        for data in sender.addresses! {
            var storage = sockaddr_storage()
            data.getBytes(&storage, length: sizeof(sockaddr_storage))
            
            switch(Int32(storage.ss_family)) {
                case AF_INET6:
                    let addr6 = withUnsafePointer(&storage, {UnsafePointer<sockaddr_in6>($0).memory})
                    print("Building an  IPv6 address host and port")
//                    IP = String(CString: inet_ntoa(addr6.sin6_addr), encoding: NSASCIIStringEncoding)!
//                    port = sender.port
//                    host = sender.hostName!
                    break
                case AF_INET:
                    print("Building an  IPv4 address host and port")
                    let addr4 = withUnsafePointer(&storage, {UnsafePointer<sockaddr_in>($0).memory})
                    IP = String(CString: inet_ntoa(addr4.sin_addr), encoding: NSASCIIStringEncoding)!
                    port = sender.port
                    host = sender.hostName!
                    IP = host.substringToIndex(host.endIndex.predecessor()).lowercaseString
                    break
                default:
                    print("Address IP not obtained or unreadable")
            }
        }
        connectToDevice()
    }
    
    func netService(sender: NSNetService, didNotResolve errorDict: [String : NSNumber]) {
        print("netService: didNotResolve:  \(errorDict.description)")
        
        let title = Constants.kAlertTitleNetServiceDidNotResolve
        let message = errorDict.debugDescription
        let obj = [Constants.kConstantTitleText:title,
            Constants.kConstantMessageText:message]
        
        dispatch_async(dispatch_get_main_queue(), {
            NSNotificationCenter.defaultCenter().postNotificationName(Constants.kNetworkManagerNetServiceErrorDidNotResolve, object:obj)
        })
    }
    
    func netServiceDidStop(sender: NSNetService) {
        print("netServiceDidStop:  \(sender.name)")
    }
    
    func netService(sender: NSNetService, didUpdateTXTRecordData data: NSData) {
        print("netService: didUpdateTXTRecordData:  \(data.description)")
    }
    
    func netService(sender: NSNetService, didAcceptConnectionWithInputStream inputStream: NSInputStream, outputStream: NSOutputStream) {
        print("netService: didAcceptConnectionWithInputStream: inputStream: outputStream: \(inputStream.description), \(outputStream.description)")
    }
    
    func dumpResponse(dict:[String:AnyObject]) {
        print("Entire Dictionary : \(dict)")
    }
    
}

enum HMACAlgorithm {
    case MD5, SHA1, SHA224, SHA256, SHA384, SHA512
    
    func toCCHmacAlgorithm() -> CCHmacAlgorithm {
        var result: Int = 0
        switch self {
        case .SHA1:
            result = kCCHmacAlgSHA1
        case .MD5:
            result = kCCHmacAlgMD5
        case .SHA256:
            result = kCCHmacAlgSHA256
        case .SHA384:
            result = kCCHmacAlgSHA384
        case .SHA512:
            result = kCCHmacAlgSHA512
        case .SHA224:
            result = kCCHmacAlgSHA224
        }
        return CCHmacAlgorithm(result)
    }
    
    func digestLength() -> Int {
        var result: CInt = 0
        switch self {
        case .MD5:
            result = CC_MD5_DIGEST_LENGTH
        case .SHA1:
            result = CC_SHA1_DIGEST_LENGTH
        case .SHA224:
            result = CC_SHA224_DIGEST_LENGTH
        case .SHA256:
            result = CC_SHA256_DIGEST_LENGTH
        case .SHA384:
            result = CC_SHA384_DIGEST_LENGTH
        case .SHA512:
            result = CC_SHA512_DIGEST_LENGTH
        }
        return Int(result)
    }
}

extension String {
    func hmac(algorithm: HMACAlgorithm, key: String) -> String {
        let cKey = key.cStringUsingEncoding(NSASCIIStringEncoding)
        let digestLen = algorithm.digestLength()
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen)

        CCHmac(algorithm.toCCHmacAlgorithm(), cKey!, (cKey?.count)!, self, self.characters.count, result)
        
        let hmacData:NSData = NSData(bytes: result, length: digestLen)
        let base64Data = hmacData
            .base64EncodedStringWithOptions(.EncodingEndLineWithCarriageReturn).removeCarriageReturn()
        
        return String(base64Data)
    }
    
    func removeCarriageReturn() -> String {
        return self.stringByReplacingOccurrencesOfString("\n", withString: "")
    }
}