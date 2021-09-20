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
    }
    private let userDefaults = UserDefaults.standard

    var isLoggedIn: Bool {
        set {
            userDefaults.setValue(newValue, forKey: Key.login)
        }
        get {
            return userDefaults.bool(forKey: Key.login)
        }
    }
}
