//
//  AppDelegate.swift
//  DiffableDataSourceChatBootcamp
//
//  Created by Adam Yoneda on 2024/09/06.
//

import UIKit
import FirebaseCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UINavigationController(rootViewController: MainViewController())
        window.makeKeyAndVisible()
        
        self.window = window
        
        FirebaseApp.configure()
        
        return true
    }
}

// グローバル変数 (シングルトン)
class GlobalVar {
    
    private init() {}
    static var shared = GlobalVar()
    
    var loginUser: User?
    
    // スタンプのUIImage
    let defaultStickers = [
        UIImage(named: "default1"), UIImage(named: "default2"), UIImage(named: "default3"),
        UIImage(named: "default4"), UIImage(named: "default5"), UIImage(named: "default6"),
        UIImage(named: "default7"), UIImage(named: "default8"), UIImage(named: "default9"),
        UIImage(named: "default10")
    ] as! [UIImage]
    
    // スタンプの画像名
    let defaultStickerIdentifier = [
        "default1", "default2", "default3", "default4", "default5",
        "default6", "default7", "default8", "default9", "default10"
    ]
}
