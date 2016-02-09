//
//  UILabel.swift
//  MoodController
//
//  Created by Jason Owens on 12/17/15.
//  Copyright © 2015 MoodMedia. All rights reserved.
//

import UIKit

extension UILabel {    
    
    func getCustomLabel(customTitle:String, size:CGFloat) -> UILabel {
        self.font = UIFont(name: getCustomFont(), size: size)!
        self.textColor = ThemeManager.currentTheme().mainColor
        self.attributedText = NSMutableAttributedString(string: customTitle)
        self.textAlignment = .Center
        self.sizeToFit()
        
        return self
    }
    
    func getCustomFont() -> String {
        return "Korolev-Light"
    }
    
    func getCustomBoldFont() -> String {
        return "Korolev-Bold"
    }
}
