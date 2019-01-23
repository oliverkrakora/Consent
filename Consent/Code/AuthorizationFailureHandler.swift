//
//  AuthorizationFailureHandler.swift
//  Consent
//
//  Created by Oliver Krakora on 23.01.19.
//  Copyright © 2019 Oliver Krakora. All rights reserved.
//

import Foundation

/// A protocol for handling authorization failures
public protocol AuthorizationFailureHandler {
    func handleAuthorizationFailure(for contentType: ContentType)
}

/// A AuthorizationFailureHandler that will display an alert to open the app settings so the user can update the privacy settings
public struct AuthorizationFailureAlertHandler: AuthorizationFailureHandler {
    public let title: String
    public let message: String
    public let showSettingsActionTitle: String
    public let cancelActionTitle: String
    public let viewController: UIViewController
    
    public init(title: String, message: String, showSettingsTitle: String = "Settings", cancelTitle: String = "Ok", vc: UIViewController) {
        self.title = title
        self.message = message
        self.showSettingsActionTitle = showSettingsTitle
        self.cancelActionTitle = cancelTitle
        self.viewController = vc
    }
    
    public func handleAuthorizationFailure(for contentType: ContentType) {
        UIAlertController.openSettingsAlert(with: title,
                             message: message,
                             cancelActionTitle: cancelActionTitle,
                             settingsActionTitle: showSettingsActionTitle,
                             vc: viewController)
    }
}
