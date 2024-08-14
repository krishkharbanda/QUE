//
//  AppDelegate.swift
//  QUE
//
//  Created by Krish Kharbanda on 7/30/21.
//

import UIKit
import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        // Override point for customization after application launch.
        guard let splitViewController = window?.rootViewController as? UISplitViewController else {
            return false
        }
        splitViewController.overrideUserInterfaceStyle = .dark
        guard let navigationController = splitViewController.viewControllers.last as? UINavigationController else {
            return false
        }
        navigationController.overrideUserInterfaceStyle = .dark
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        splitViewController.delegate = self
        window?.overrideUserInterfaceStyle = .dark
        return true
    }
    
    // MARK: - Split view
    
    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController: UIViewController,
                             onto primaryViewController: UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else {
            return false
        }
        
        guard let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController else {
            return false
        }
        
        if topAsDetailController.detailItem == nil {
            return true
        }
        
        return false
    }
}
