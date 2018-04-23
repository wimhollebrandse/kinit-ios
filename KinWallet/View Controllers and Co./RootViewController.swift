//
//  RootViewController.swift
//  KinWallet
//
//  Copyright © 2018 KinFoundation. All rights reserved.
//

import UIKit
import Crashlytics

private let taskFetchTimeout: TimeInterval = 6
private let creatingAccountTimeout: TimeInterval = 25

class RootViewController: UIViewController {
    fileprivate var splashScreenViewController: SplashScreenViewController? = SplashScreenViewController()
    fileprivate let rootTabBarController = StoryboardScene.Main.rootTabBarController.instantiate()
    weak var walletCreationNoticeViewController: NoticeViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        if Kin.shared.accountStatus == .activated {
            DispatchQueue.main.asyncAfter(deadline: .now() + taskFetchTimeout) {
                self.dismissSplashIfNeeded()
            }
        } else {
            splashScreenViewController!.creatingAccount = true
            startWalletCreationTimeout()
        }

        addAndFit(rootTabBarController)
        addAndFit(splashScreenViewController!)
    }

    override var childViewControllerForStatusBarStyle: UIViewController? {
        return childViewControllers.last
    }

    func dismissSplashIfNeeded() {
        guard let splash = splashScreenViewController else {
            return
        }

        self.splashScreenViewController = nil

        UIView.animate(withDuration: 0.25, animations: {
            splash.view.alpha = 0
        }, completion: { _ in
            splash.remove()
            self.setNeedsStatusBarAppearanceUpdate()
        })
    }

    private func showWalletCreationFailed() {
        guard walletCreationNoticeViewController == nil else {
            return
        }

        let supportAttributes: [NSAttributedStringKey: Any] = [.font: FontFamily.Roboto.regular.font(size: 14),
                                                               .foregroundColor: UIColor.kin.appTint,
                                                               .underlineStyle: NSUnderlineStyle.styleSingle.rawValue]
        let supportAttributedString = NSMutableAttributedString(string: "or contact support",
                                                                attributes: supportAttributes)
        let orAttributes: [NSAttributedStringKey: Any] = [.foregroundColor: UIColor.kin.gray,
                                                          .underlineStyle: NSUnderlineStyle.styleNone.rawValue]
        supportAttributedString.addAttributes(orAttributes, range: NSRange(location: 0, length: 3))

        let buttonConfiguration = NoticeButtonConfiguration(title: "Try Again",
                                                            mode: .stroke,
                                                            additionalMessage: supportAttributedString)
        let noticeViewController = StoryboardScene.Main.noticeViewController.instantiate()
        noticeViewController.delegate = self
        noticeViewController.notice = Notice(image: Asset.walletCreationFailed.image,
                                             title: "We were unable to create a wallet for you",
                                             subtitle: "Please check your internet connection & try again.",
                                             buttonConfiguration: buttonConfiguration,
                                             displayType: .imageFirst)
        present(noticeViewController, animated: true)

        walletCreationNoticeViewController = noticeViewController

        Analytics.logEvent(Events.Analytics.ViewErrorPage(errorType: .onboarding))
    }

    func startWalletCreationTimeout() {
        DispatchQueue.main.asyncAfter(deadline: .now() + creatingAccountTimeout) {
            guard self.splashScreenViewController != nil else {
                return
            }

            self.showWalletCreationFailed()
        }
    }

    func appLaunched() {
        if let currentUser = User.current {
            KLogVerbose("User \(currentUser.userId) with device token \(currentUser.deviceToken ?? "No token")")
            Kin.shared.performOnboardingIfNeeded().then {
                self.onboardSucceeded($0)
            }

            #if !TESTS
            if Configuration.shared.testFairyKey != nil {
                TestFairy.setAttribute("userId", withValue: currentUser.userId)
            }
            #endif

            Crashlytics.sharedInstance().setUserIdentifier(currentUser.userId)

            UIApplication.shared.registerForRemoteNotifications()
            WebRequests.appLaunch().withCompletion { success, _ in
                KLogVerbose("App Launch: \(success.boolValue)")
            }.load(with: KinWebService.shared)

            KinLoader.shared.loadAllData()
        } else {
            Kin.shared.resetKeyStore()
            let user = User.createNew()
            let userRegistration = WebRequests.userRegistrationRequest(for: user)
            KinWebService.shared.load(userRegistration.withCompletion { success, error in
                KLogVerbose("User registration: \(success.boolValue)")
                guard success.boolValue else {
                    let reason = error?.localizedDescription ?? "Unknown error"
                    let event = Events.Log.UserRegistrationFailed(failureReason: reason)
                    Analytics.logEvent(event)
                    return
                }

                Analytics.userId = user.userId
                Analytics.deviceId = user.deviceId
                Analytics.logEvent(Events.Business.UserRegistered())
                user.save()

                KinLoader.shared.loadAllData()

                Kin.shared.performOnboardingIfNeeded().then {
                    self.onboardSucceeded($0)
                }

                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            })
        }
    }

    func onboardSucceeded(_ success: Bool) {
        guard success else {
            showWalletCreationFailed()
            return
        }

        guard var user = User.current else {
            return
        }

        user.publicAddress = Kin.shared.publicAddress
        user.save()

        DispatchQueue.main.async {
            if self.walletCreationNoticeViewController == nil {
                AppDelegate.shared.dismissSplashIfNeeded()
            }
        }
    }
}

extension RootViewController: NoticeViewControllerDelegate {
    func noticeViewControllerDidTapButton(_ viewController: NoticeViewController) {
        Analytics.logEvent(Events.Analytics.ClickRetryButtonOnErrorPage(errorType: .onboarding))

        dismiss(animated: true) { [weak self] in
            self?.startWalletCreationTimeout()
            self?.appLaunched()
        }
    }

    func noticeViewControllerDidAdditionalMessage(_ viewController: NoticeViewController) {
        Analytics.logEvent(Events.Analytics.ClickContactLinkOnErrorPage(errorType: .onboarding))
        KinSupportViewController.present(from: viewController)
    }
}