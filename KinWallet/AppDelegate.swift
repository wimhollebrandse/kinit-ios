//
//  AppDelegate.swift
//  KinWallet
//
//  Copyright © 2018 KinFoundation. All rights reserved.
//

import Fabric
import Crashlytics
import UIKit
import KinSDK
import Firebase
import FirebaseAuth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var notificationHandler: NotificationHandler?

    fileprivate let rootViewController = RootViewController()

    //swiftlint:disable:next line_length
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        if !runningTests() {
            Fabric.with([Crashlytics.self])

            #if !TESTS
            if let testFairyKey = Configuration.shared.testFairyKey {
                TestFairy.begin(testFairyKey)
            }
            #endif
        }

        FirebaseApp.configure()

        #if DEBUG
            logLevel = .verbose
        #endif

        if #available(iOS 10.0, *) {
            notificationHandler = iOS10NotificationHandler()
        }

        applyAppearance()

        let currentUser = User.current
        Analytics.start(userId: currentUser?.userId, deviceId: currentUser?.deviceId)

        window = UIWindow()
        window!.makeKeyAndVisible()
        window!.rootViewController = rootViewController
        rootViewController.appLaunched()

        notificationHandler?.arePermissionsGranted { granted in
            Analytics.setUserProperty(Events.UserProperties.pushEnabled, with: granted)
        }

        if
            let launchOptions = launchOptions,
            let notificationUserInfo = launchOptions[.remoteNotification] as? [AnyHashable: Any] {
            logNotificationOpened(with: notificationUserInfo)
        }

        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        User.current?.updateDeviceTokenIfNeeded(deviceToken.hexString)

        let tokenType: AuthAPNSTokenType

        #if DEBUG
        tokenType = .sandbox
        #else
        tokenType = .prod
        #endif

        Auth.auth().setAPNSToken(deviceToken, type: tokenType)
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }

        guard application.applicationState == .inactive else {
            KLogVerbose("Received push while in foreground:\n\(userInfo)")
            return
        }

        logNotificationOpened(with: userInfo)
    }
}

extension AppDelegate {
    @discardableResult func dismissSplashIfNeeded() -> Bool {
        return rootViewController.dismissSplashIfNeeded()
    }

    var isShowingSplashScreen: Bool {
        return rootViewController.isShowingSplashScreen
    }
}

private func runningTests() -> Bool {
    return ProcessInfo().environment["XCInjectBundleInto"] != nil
}
