//
//  LoginVM.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 20.09.2021.
//

import Foundation

class LoginVM {
    private var service = LoginService()
    private let router: LoginRouter

    private(set) var error: Bound<String> = Bound("")

    init(router: LoginRouter) {
        self.router = router
    }

    func login(email: String, password: String) {
        guard email == "app@astartecosmetics.com", password == "123456" else {
            error.value = "Invalid credentials"
            return
        }
        service.isLoggedIn = true
        router.presentCamera()
    }
}
