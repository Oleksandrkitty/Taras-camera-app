//
//  AppDelegate.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 02.06.2021.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        showStartScreen()
        return true
    }

    private func showStartScreen() {
        let window = UIWindow()
        window.rootViewController = ScreenBuilder.camera()
        self.window = window
        window.makeKeyAndVisible()
    }
}
