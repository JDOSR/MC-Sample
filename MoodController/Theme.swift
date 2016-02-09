//
//  Theme.swift
//  MoodController
//
//  Created by Jason Owens on 12/14/15.
//  Copyright © 2015 MoodMedia. All rights reserved.
//

import UIKit


let SelectedThemeKey = "SelectedTheme"

enum Theme : Int {
    case Default, Dark, Graphical
    
    var mainColor : UIColor {
        switch self {
        case .Default:
            return UIColor(red: 190.0/255.0, green: 39.0/255.0, blue: 52.0/255.0, alpha: 1.0)
        case .Dark:
            return UIColor(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 1.0)
        case .Graphical:
            return UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        }
    }
    
    
}

struct ThemeManager {
    
    static func applyTheme(theme: Theme) {
        // 1
        NSUserDefaults.standardUserDefaults().setValue(theme.rawValue, forKey: SelectedThemeKey)
        NSUserDefaults.standardUserDefaults().synchronize()
        
        // 2
        let sharedApplication = UIApplication.sharedApplication()
        sharedApplication.delegate?.window??.tintColor = theme.mainColor
        
    }
    
    static func currentTheme() -> Theme {
        if let storedTheme = NSUserDefaults.standardUserDefaults().valueForKey(SelectedThemeKey)?.integerValue {
            return Theme(rawValue: storedTheme)!
        } else {
            return .Default
        }
    }
}