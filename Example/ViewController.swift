//
//  ViewController.swift
//  Example
//
//  Created by Oliver Krakora on 28.11.18.
//  Copyright © 2018 Oliver Krakora. All rights reserved.
//

import UIKit
import Consent
import AVKit

class ViewController: UITableViewController {
    
    func requestAccess(for content: Consent.ContentType) {
        
        let appName = "Example"
        
        let errorTitle = "\(appName) can't access \(content.description)"
        let errorMessage = "\(appName) needs access to the device camera to demonstrate it's functionality. You can activate \(content.description) access in the device settings."
        
        let preconsentTitle = "Allow \(appName) to access \(content.description)?"
        let preconsentMessage = "\(appName) needs access to \(content.description) to demonstrate it's functionality."
        
        let failureHandler = Consent.AuthorizationFailureAlertHandler(title: errorTitle,
            message: errorMessage, vc: self)
        
        let consentHandler = Consent.PreconsentAlertHandler(title: preconsentTitle,
                                                            message: preconsentMessage,
                                                            allowActionTitle: "Allow",
                                                            denyActionTitle: "Cancel",
                                                            vc: self)
        
        Consent.requestAccess(for: content, preconsentHandler: consentHandler, failureHandler: failureHandler) { canAccess in
            print("can access \(content.description): \(canAccess)")
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0: requestAccess(for: .camera)
        case 1: requestAccess(for: .photoLibrary)
        case 2: requestAccess(for: .calendar(.event))
        case 3: requestAccess(for: .contacts)
        default: break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
