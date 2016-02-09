//
//  Breadcrumbs.swift
//  MoodController
//
//  Created by Jason Owens on 12/13/15.
//  Copyright © 2015 MoodMedia. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class Breadcrumbs : UIView {
    
    private struct Params {
        static let firstIndicatorXPos: CGFloat = 30.0
        static let firstIndicatorLabelXPos: CGFloat = 16.0
        static let firstIndicatorLineXPos: CGFloat = 38.0
        static let spacing: Int = 50
        static let labelSpacing: Int = 22
        static let indicators: Int = 5
        static let indicatorSize: Int = 22
        static let indicatorLabelSize: Int = 50
        static let lineLength: CGFloat = 44.0
    }
    
    @IBInspectable var currentPage = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var checkmarkIndicators = [UIImageView]()
    var checkmarkLabels = [UILabel]()
    var lineViews = [UIImageView]()
    var indicatorNames = ["DISCOVER", "PROFUSION", "SET NAME", "NETWORK", "MUSIC"]
    
    override class func layerClass()->AnyClass{
        return CAGradientLayer.self
    }
    
    convenience init (cp : Int) {
        self.init(frame:CGRect.zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    // MARK: Initialization
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
   
    func buildCrumbs(cp: Int) {
        let emptyStatusImage = UIImage(named: "discover_empty")
        let filledStatusImage = UIImage(named: "discover_filled")
        let successStatusImage = UIImage(named: "discover_success")
        
        for (index, item) in indicatorNames.enumerate() {
            //Add Image
            let indicator = UIImageView()
            indicator.tag = index
            let indLabel = UILabel(frame: CGRectZero).getCustomLabel(item, size: 10.0)
            indLabel.tag = index*100
            
            if index > currentPage {
                indicator.image = emptyStatusImage
                indLabel.textColor = UIColor.grayColor()
            } else if index == currentPage {
                indicator.image = filledStatusImage
                indLabel.textColor = UIColor.blackColor()
            } else if index < currentPage {
                indicator.image = successStatusImage
                indLabel.textColor = UIColor.blackColor()
            }
            
            checkmarkIndicators += [indicator]
            checkmarkLabels += [indLabel]
            
            addSubview(indicator)
            addSubview(indLabel)
            
            if(index < indicatorNames.count - 1) {
                let posX = (indicator.frame.origin.x + indicator.frame.width)
                let posY = (indicator.frame.origin.y + CGFloat(Params.indicatorSize)/2)
                let lineView = UIImageView(image: drawConnectionLine(index, startingPoint: CGPoint(x: posX, y: posY)))
                lineViews += [lineView]
                addSubview(lineView)
            }
            
        }
    }
    
    
    override func layoutSubviews() {
        var indicatorFrame = CGRect(x:0, y:0, width: Params.indicatorSize, height: Params.indicatorSize)
        var indicatorLabelFrame = CGRect(x:0, y:24, width: Params.indicatorLabelSize, height: 14)
        var lineFrame = CGRect(x:0, y:0, width: Params.lineLength, height: 1)
        
        for (index, button) in checkmarkIndicators.enumerate() {
            indicatorFrame.origin.x = CGFloat(Params.firstIndicatorXPos) + CGFloat(index * (Params.indicatorSize + Params.spacing))
            button.frame = indicatorFrame
        }
        
        for (index, label) in checkmarkLabels.enumerate() {
            indicatorLabelFrame.origin.x = CGFloat(Params.firstIndicatorLabelXPos) + CGFloat(index * (Params.indicatorLabelSize + Params.labelSpacing))
            label.frame = indicatorLabelFrame
        }
        
        for(index, lvs) in lineViews.enumerate() {
            let imgView = checkmarkIndicators[index]
            lineFrame.origin.x = CGFloat(CGRectGetMinX(imgView.frame) + CGRectGetWidth(imgView.frame) + 3)
            lineFrame.origin.y = CGFloat(CGRectGetMinY(imgView.frame) + CGRectGetHeight(imgView.frame)/2)
            lvs.frame = lineFrame
        }
    }
    
    override func intrinsicContentSize() -> CGSize {
        let width = (Params.indicatorSize + Params.spacing) * Params.indicators
        return CGSize(width: width, height: Params.indicatorSize)
    }
    
    func drawConnectionLine(index: Int, startingPoint: CGPoint) -> UIImage {
        let newSize = CGSize(width: Params.lineLength, height: 10.0)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        
        let context = UIGraphicsGetCurrentContext()
        if(index >= currentPage) {
            CGContextSetFillColorWithColor(context, UIColor.lightGrayColor().CGColor)
        } else if(index < currentPage) {
            CGContextSetFillColorWithColor(context, UIColor.blackColor().CGColor)
        }
        CGContextFillRect(context, CGRect(origin: CGPointZero, size: newSize))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func updateBreadcrumb(indicator:Int) {
        let successStatusImage = UIImage(named: "discover_success")

        if let crumbToUpdate = self.viewWithTag(indicator) as? UIImageView {
            crumbToUpdate.image = successStatusImage
            if let crumbLabel = self.viewWithTag(indicator*100)! as? UILabel {
                crumbLabel.textColor = UIColor.blackColor()
            }
        }
    }
}