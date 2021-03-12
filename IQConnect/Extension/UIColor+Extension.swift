//
//  UIColor+Extension.swift
//  IQConnect
//
//  Created by SuperDev on 07.01.2021.
//

import UIKit

extension UIColor {
    
    static let appBlueColor = UIColor(hex: 0x3498DB)
    static let appGreenColor = UIColor(hex: 0x11b900)
    static let appRedColor = UIColor(hex: 0xdb3434)
    static let appButtonBlueColor = UIColor(hex: 0x42A5F5)
    static let appButtonRedColor = UIColor(hex: 0xd50000)
    
    convenience init(red: Int, green: Int, blue: Int, withAlpha alpha: CGFloat) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: alpha)
    }
    
    
    convenience init(hex:Int, _ alpha: CGFloat = 1.0) {
        self.init(red:(hex >> 16) & 0xff, green:(hex >> 8) & 0xff, blue:hex & 0xff, withAlpha: alpha)
    }
    
//    convenience init(hexString: String) {
//        var cString:String = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
//
//        if (cString.hasPrefix("#")) {
//            cString.remove(at: cString.startIndex)
//        }
//
//        if ((cString.count) != 6) {
//            self.init()
//            return
//        }
//
//        var rgbValue:UInt64 = 0
//        Scanner(string: cString).scanHexInt64(&rgbValue)
//
//        self.init(
//            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
//            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
//            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
//            alpha: CGFloat(1.0)
//        )
//    }
}
