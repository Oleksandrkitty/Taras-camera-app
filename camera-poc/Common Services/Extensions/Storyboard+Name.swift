//
//  Storyboard+Name.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 02.06.2021.
//

import UIKit

extension UIStoryboard {
    static var camera: UIStoryboard {
        return UIStoryboard(name: "Camera", bundle: nil)
    }
    
    static var photosList: UIStoryboard {
        return UIStoryboard(name: "PhotosList", bundle: nil)
    }

    static var auth: UIStoryboard {
        return UIStoryboard(name: "Auth", bundle: nil)
    }
}
