//
//  GradientView.swift
//  English Helper
//
//  Created by Матвей Анисович on 29.09.2020.
//  Copyright © 2020 Матвей Анисович. All rights reserved.
//

import UIKit
@IBDesignable
class ViewWithShadow: UIView {
    
    private var oldShadowLayer: CAShapeLayer?
    private var shadowLayer: CAShapeLayer!
    
    var isDarkMode: Bool {
        if #available(iOS 13.0, *) {
            return self.traitCollection.userInterfaceStyle == .dark
        }
        else {
            return false
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = 15
        
        shadowLayer = CAShapeLayer()
        shadowLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: self.layer.cornerRadius).cgPath
        shadowLayer.fillColor = self.backgroundColor?.cgColor
        
        shadowLayer.shadowColor = UIColor.darkGray.cgColor
        shadowLayer.shadowPath = shadowLayer.path
        shadowLayer.shadowOffset = CGSize(width: 0, height: 2)
        shadowLayer.shadowOpacity = 0.3
        shadowLayer.shadowRadius = CGFloat(5)
        
        if isDarkMode {
            shadowLayer.opacity = 0
        }
        
        if oldShadowLayer != nil {
            layer.replaceSublayer(oldShadowLayer!, with: shadowLayer)
        } else {
            layer.insertSublayer(shadowLayer, below: nil)
        }
        oldShadowLayer = shadowLayer
        
    }
}

