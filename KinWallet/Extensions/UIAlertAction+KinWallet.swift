//
//  UIAlertAction+KinWallet.swift
//  Kinit
//

import UIKit

extension UIAlertAction {
    static func cancel(handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertAction {
        return UIAlertAction(title: "Cancel", style: .cancel, handler: handler)
    }

    static func ok(handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertAction {
        return UIAlertAction(title: "OK", style: .default, handler: handler)
    }
}
