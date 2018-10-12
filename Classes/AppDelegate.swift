//
//  AppDelegate.swift
//  SpotX-Demo-Swift
//

import UIKit
import SpotX

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    self.window = UIWindow(frame: UIScreen.main.bounds)
    self.window?.rootViewController = UIStoryboard(name: "MainViewController", bundle: nil).instantiateInitialViewController()
    self.window?.makeKeyAndVisible()
    SpotX.debugMode(true)
    return true
  }

}

