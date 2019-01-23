//
//  UIAlertController+Extension.swift
//  Consent
//
//  Created by Oliver Krakora on 23.01.19.
//  Copyright © 2019 Oliver Krakora. All rights reserved.
//

import UIKit

extension UIAlertController {
    
    public convenience init(with title: String, message: String, actionTitle: String, cancelTitle: String, cancelAction: (() -> Void)? = nil, action: @escaping (() -> Void)) {
        self.init(title: title, message: message, preferredStyle: .alert)
        addAction(UIAlertAction(title: cancelTitle, style: .cancel) { _ in
            cancelAction?()
        })
        
        addAction(UIAlertAction(title: actionTitle, style: .default, handler: { _ in
            action()
        }))
    }
    
    public static func openSettingsAlert(with title: String, message: String, cancelActionTitle: String, settingsActionTitle: String, vc: UIViewController) {
        let alertVC = UIAlertController(with: title, message: message, actionTitle: settingsActionTitle, cancelTitle: cancelActionTitle) {
            let settingsURL = URL(string: UIApplication.openSettingsURLString)!
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        }
        vc.present(alertVC, animated: true, completion: nil)
    }
}
