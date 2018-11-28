//
//  ViewController.swift
//  Example
//
//  Created by Oliver Krakora on 28.11.18.
//  Copyright © 2018 Oliver Krakora. All rights reserved.
//

import UIKit
import Consent

class ViewController: UITableViewController {
    
    func requestAccess(for content: PrivacyController.ContentType) {
        let alertConfig = PrivacyController.AuthorizationAlertConfiguration(title: "XYZ can't access \(content.description)",
            message: "Please activate \(content.description) access for xyz app.", vc: self)
        
        PrivacyController.requestAccess(for: content, alertConfiguration: alertConfig) { isAuthorized in
            print("Can access \(content.description): \(isAuthorized)")
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
