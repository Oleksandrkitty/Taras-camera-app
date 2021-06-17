//
//  AppDelegate.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 02.06.2021.
//

import UIKit
import AWSS3

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        initializeS3()
        showStartScreen()
        return true
    }

    private func showStartScreen() {
        let window = UIWindow()
        window.rootViewController = ScreenBuilder.camera()
        self.window = window
        window.makeKeyAndVisible()
    }
    
    func initializeS3() {
        let poolId = "us-east-2:f7de873a-0dd7-42a4-93e6-c1e8e6cee36d"
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .USEast2, identityPoolId: poolId)
        let configuration = AWSServiceConfiguration(region: .USEast2, credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
    }
}
