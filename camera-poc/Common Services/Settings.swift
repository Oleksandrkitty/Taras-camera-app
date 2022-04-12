//
//  Settings.swift
//  Astarte
//
//  Created by Taras Chernyshenko on 02.04.2022.
//

import Foundation
import UIKit

class Settings {
    private struct Key {
        static let faceDistance = "ReferalFaceDistanceKey"
        static let eyesDistance = "ReferalEyesDistance"
    }
    private let userDefaults = UserDefaults.standard

    var referalFaceDistance: Int {
        return 40
    }
    
    var referalEyesDistance: Int {
        return Int(UIScreen.main.bounds.width - 320) / 7 + 57
    }
}
