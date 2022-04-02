//
//  Settings.swift
//  Astarte
//
//  Created by Taras Chernyshenko on 02.04.2022.
//

import Foundation

class Settings {
    private struct Key {
        static let faceDistance = "ReferalFaceDistanceKey"
        static let eyesDistance = "ReferalEyesDistance"
    }
    private let userDefaults = UserDefaults.standard

    var referalFaceDistance: Int {
        set {
            userDefaults.setValue(newValue, forKey: Key.faceDistance)
        }
        get {
            userDefaults.integer(forKey: Key.faceDistance)
        }
    }
    
    var referalEyesDistance: Int {
        set {
            userDefaults.setValue(newValue, forKey: Key.eyesDistance)
        }
        get {
            userDefaults.integer(forKey: Key.eyesDistance)
        }
    }
}
