//
//  PreconsentHandler.swift
//  Consent
//
//  Created by Oliver Krakora on 23.01.19.
//  Copyright © 2019 Oliver Krakora. All rights reserved.
//

import UIKit

/// A protocol for requesting users consent before the system displays a consent dialog
public protocol PreconsentHandler {
    func handlePreconsent(for contentType: ContentType, consentCompletion: @escaping (() -> Void))
}

/// A PreconsentHandler that will display an alert with two buttions describing why your app wants access to a specific resource
public struct PreconsentAlertHandler: PreconsentHandler {
    let title: String
    let message: String
    let consentTitle: String
    let denyTitle: String
    let viewController: UIViewController
    
    public init(title: String, message: String, allowActionTitle: String = "Allow", denyActionTitle: String = "Cancel", vc: UIViewController) {
        self.title = title
        self.message = message
        self.consentTitle = allowActionTitle
        self.denyTitle = denyActionTitle
        self.viewController = vc
    }
    
    public func handlePreconsent(for contentType: ContentType, consentCompletion: @escaping (() -> Void)) {
        let alertVC = UIAlertController(with: title, message: message, actionTitle: consentTitle, cancelTitle: denyTitle) {
            consentCompletion()
        }
        viewController.present(alertVC, animated: true, completion: nil)
    }
}
