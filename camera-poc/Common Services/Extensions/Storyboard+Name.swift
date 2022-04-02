//
//  Storyboard+Name.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 02.06.2021.
//

import UIKit

extension UIStoryboard {
    static var auth: UIStoryboard {
        return UIStoryboard(name: "Auth", bundle: nil)
    }
    
    static var camera: UIStoryboard {
        return UIStoryboard(name: "Camera", bundle: nil)
    }

    static var distanceCalibration: UIStoryboard {
        return UIStoryboard(name: "DistanceCalibration", bundle: nil)
    }
    
    static var photosList: UIStoryboard {
        return UIStoryboard(name: "PhotosList", bundle: nil)
    }
}
