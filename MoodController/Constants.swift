//
//  Constants.swift
//  MoodController
//
//  Created by Jason Owens on 12/22/15.
//  Copyright © 2015 MoodMedia. All rights reserved.
//

//MARK: Notification Keys

struct Constants {
    static let kNetworkManagerWillUpdateTableView           = "kNetworkManagerWillUpdateTableView"
    static let kNetworkManagerDidSaveConfigurationToDevice  = "kNetworkManagerDidSaveConfigurationToDevice"
    static let kNetworkManagerDidLogUserIn                  = "kNetworkManagerDidLogUserIn"
    static let kNetworkManagerDidLogUserOut                 = "kNetworkManagerDidLogUserOut"
    static let kNetworkManagerResetPageToDefaultState       = "kNetworkManagerResetPageToDefaultState"
    static let kNetworkManagerGetEditConfigurationToScan    = "kNetworkManagerGetEditConfigurationToScan"
    static let kNetworkManagerHasEditLock                   = "kNetworkManagerHasEditLock"
    static let kNetworkManagerDidRetreiveNetworkStatus      = "kNetworkManagerDidRetreiveNetworkStatus"
    static let kNetworkManagerWillScanForNetworks           = "kNetworkManagerWillScanForNetworks"
    static let kNetworkManagerDidFindDomain                 = "kNetworkManagerDidFindDomain"
    static let kNetworkManagerDidReceiveActivationCode      = "kNetworkManagerDidReceiveActivationCode"
    static let kNetworkManagerDidRequestToActivate          = "kNetworkManagerDidRequestToActivate"
    static let kNetworkManagerNetServiceErrorDidNotResolve  = "kNetworkManagerNetServiceErrorDidNotResolve"
    static let kNetworkManagerDidStopISMService             = "kNetworkManagerDidStopISMService"
    static let kNetworkManagerLoginErrorNotification        = "kNetworkManagerLoginErrorNotification"
    static let kNetworkManagerStopSearchingForServices      = "kNetworkManagerStopSearchingForServices"
    static let kNetworkManagerStartSearchingForServices     = "kNetworkManagerStartSearchingForServices"



    //MARK: Display Names
    static let kNetworkManagerWifiOptionName    = "Mood Controller by Mood"
    static let deviceName                       = "profusion"

    //MARK: Named Segues
    static let setupPandoraSegue                = "setupPandoraSegue"
    static let newPro                           = "newProFusion"
    static let existPro                         = "existingProFusion"
    static let connectProfusion                 = "connectProFusion"
    static let set_name_segue                   = "toSetNameSegue"
    static let to_wired_segue                   = "toWiredOrWiFiSegue"
    static let statusSegue                      = "statusSegue"
    static let wiredSettingsSegue               = "wiredSettingsSegue"
    static let activationSegue                  = "activationSegue"
    static let toPandoraAccount                 = "toPandoraAccount"
    static let toPandoraAccount2                = "toPandoraAccount2"
    static let toRenameExistingProfusionDevice  = "toRenameExistingProfusionDevice"
    static let kProductsessionIdKey             = "productsessionIdKey"
    static let kArchivedServicesKey             = "kArchivedServicesKey"
    
    //Error Alerts Titles and Messages
    static let kAlertRegisteredDeviceTitle          = "Device is Registered"
    static let kAlertRegisteredDeviceMessage        = "Your Profusion iO may have already been registered, please verify that this device is not currently setup"
    static let kAlertWelcomeDevicesTitle            = "No Profusion Devices"
    static let kAlertWelcomeDevicesMessage          = "You have not named a Profusion Devices as of yet, please set up a new device."
    static let kAlertTitleCheckDevice               = "Check Device"
    static let kAlertMessageCheckDevice             = "Please check that your device is in ISM mode"
    static let kAlertTitleNetServiceDidNotSearch    = "NetService Did Not Search"
    static let kAlertTitleNetServiceDidNotResolve   = "Did Not Resolve"
    
    static let kAlertSettingsRedirectTitle          = "Settings App"
    static let kAlertSettingsRedirectMessage        = "This link will take you to the Settings Application.  Select \"< Settings\" then go to Wifi to manage settings."
    
    static let kAlertFormDataEnterPasswordTitle     = "Enter WiFi Password for"
    
    static let kConstantTitleText                   = "title"
    static let kConstantMessageText                 = "message"
    static let kDescriptionWiFiAnnotation           = "Mood Corporation"
    static let kConstantTextUnavailable             = "Unavailable"
    
    static let kConstantTitleConnectToProfusion     = "Connect To Profusion"
    static let kConstantTitleLetsGetStarted         = "Let's Get Started"
    static let kConstantTitleConnectToNetwork       = "Connect to Network"
    static let kConstantTitleNameYourProfusion      = "Name Your ProFusion"
    static let kConstantTitlePandoraActivation      = "Pandora Activation.."
    static let kConstantTitleSetup                  = "Setup"
}