//
//  UIViewController+KinWallet.swift
//  KinWallet
//
//  Copyright © 2018 KinFoundation. All rights reserved.
//

import UIKit

extension UIViewController {
    func addAndFit(_ child: UIViewController, to view: UIView? = nil, viewConfiguration: ((UIView) -> Void)? = nil) {
        add(child, to: view) {
            $0.fitInSuperview()
            viewConfiguration?($0)
        }
    }

    func add(_ child: UIViewController, to view: UIView? = nil, viewConfiguration: (UIView) -> Void) {
        addChildViewController(child)
        (view ?? self.view).addSubview(child.view)
        viewConfiguration(child.view)
        child.didMove(toParentViewController: self)
    }

    func remove() {
        guard parent != nil else {
            return
        }

        willMove(toParentViewController: nil)
        removeFromParentViewController()
        view.removeFromSuperview()
    }
}

extension UIViewController {
    func addBalanceLabel() {
        let label = BalanceLabel(kin: Kin.shared)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: label)
    }
}
