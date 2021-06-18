//
//  UIDevice+ScreenSize.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 15.06.2021.
//

import UIKit

extension UIDevice {
    enum DeviceFamily: Int {
        case seven
        case sevenPlus
        case ten
        case xsMax
        case twelve
        case twelveProMax
        
        var screenSize: CGSize {
            switch self {
            case .seven:
                return CGSize(width: 375, height: 667)
            case .sevenPlus:
                return CGSize(width: 414, height: 736)
            case .ten:
                return CGSize(width: 375, height: 812)
            case .xsMax:
                return CGSize(width: 414, height: 896)
            case .twelve:
                return CGSize(width: 390, height: 844)
            case .twelveProMax:
                return CGSize(width: 428, height: 926)
            }
        }
        
        var stringValue: String {
            switch self {
            case .seven:
                return "6s/7/8/SE"
            case .sevenPlus:
                return "7/8 Plus"
            case .ten:
                return "X/XS/11 Pro/12 Mini"
            case .xsMax:
                return "11/XR/XS Max"
            case .twelve:
                return "12/12 Pro"
            case .twelveProMax:
                return "12 Pro Max"
            }
        }
    }
    
    static var deviceFamilies: [DeviceFamily] = [.seven, .sevenPlus, .ten, .xsMax, .twelve, .twelveProMax]
}
