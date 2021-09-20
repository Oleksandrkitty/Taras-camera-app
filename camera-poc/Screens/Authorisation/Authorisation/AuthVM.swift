//
//  AuthVM.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 30.07.2021.
//

import Foundation

class AuthService {
    private enum AuthKey: String {
        case userName = "UserNameKey"
    }
    private let userDefaults = UserDefaults.standard

    var userName: String? {
        set {
            userDefaults.set(newValue, forKey: AuthKey.userName.rawValue)
        }
        get {
            return userDefaults.string(forKey: AuthKey.userName.rawValue)?.lowercased()
        }
    }
}

protocol AuthVMDelegate: AnyObject {
    func didAuthorized()
}

class AuthVM {
    private let authService = AuthService()
    private let router: AuthRouter
    private weak var delegate: AuthVMDelegate!
    private(set) var error: Bound<String> = Bound("")

    init(router: AuthRouter, delegate: AuthVMDelegate) {
        self.router = router
        self.delegate = delegate
    }

    func change(userName: String) {
        if userName.isEmpty {
            error.value = "Username can't be empty"
            return
        }
        authService.userName = userName
        router.dismiss()
        delegate.didAuthorized()
    }
}
