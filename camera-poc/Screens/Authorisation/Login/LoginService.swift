//
//  LoginService.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 20.09.2021.
//

import Foundation

struct LoginService {
    private struct Key {
        static let login = "LoginKey"
        static let calibration = "DistanceToFaceCalibrationKey"
    }
    private let userDefaults = UserDefaults.standard
    private let settings = Settings()

    var isLoggedIn: Bool {
        set {
            userDefaults.setValue(newValue, forKey: Key.login)
        }
        get {
            return userDefaults.bool(forKey: Key.login)
        }
    }
    
    var isCameraCalibrated: Bool {
        return settings.referalEyesDistance > 0 && settings.referalFaceDistance > 0
    }
}
