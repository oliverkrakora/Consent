//
//  PrivacyController.swift
//  Gibble
//
//  Created by Oliver Krakora on 25.10.18.
//  Copyright © 2018 aaa - all about apps Gmbh. All rights reserved.
//

import Foundation
import AVKit
import Photos
import EventKit
import Contacts
import UserNotifications

public struct Privacy {
    
    // MARK: Definitions
    
    public typealias AVKitCompletionHandler = ((Bool) -> Void)
    
    public typealias PHKitCompletionHandler = ((PHAuthorizationStatus) -> Void)
    
    public typealias CNContactsCompletionHandler = ((Bool, Error?) -> Void)
    
    public typealias UNUserNotificationCenterCompletionHandler = ((Bool, Error?) -> Void)
    
    public typealias SimpleAuthorizationCompletionHandler = ((Bool) -> Void)
    
    public struct AuthorizationAlertConfiguration {
        public let title: String
        public let message: String
        public let showSettingsActionTitle: String
        public let cancelTitle: String
        public let viewController: UIViewController
        
        public init(title: String, message: String, showSettingsTitle: String = "Settings", cancelTitle: String = "Ok", vc: UIViewController) {
            self.title = title
            self.message = message
            self.showSettingsActionTitle = showSettingsTitle
            self.cancelTitle = cancelTitle
            self.viewController = vc
        }
    }
    
    public enum ContentType {
        case camera
        case photoLibrary
        case calendar(EKEntityType)
        case contacts
        case pushNotifications(UNAuthorizationOptions)
        
        public var requiredInfoPlistKey: String? {
            switch self {
            case .camera: return "NSCameraUsageDescription"
            case .photoLibrary: return "NSPhotoLibraryUsageDescription"
            case .calendar: return "NSCalendarsUsageDescription"
            case .contacts: return "NSContactsUsageDescription"
            case .pushNotifications: return nil
            }
        }
        
        public var description: String {
            switch self {
            case .camera: return "camera"
            case .photoLibrary: return "photos library"
            case .calendar: return "calendar"
            case .contacts: return "contacts"
            case .pushNotifications: return "push notifications"
            }
        }
    }
    
    public enum AuthorizationStatus {
        case camera(AVAuthorizationStatus)
        case photoLibrary(PHAuthorizationStatus)
        case calendar(EKAuthorizationStatus)
        case contacts(CNAuthorizationStatus)
        case pushNotifications(UNNotificationSettings, UNAuthorizationOptions)
    }
    
    public enum AuthorizationType {
        case camera(AVKitCompletionHandler)
        case photosLibrary(PHKitCompletionHandler)
        case calendar(EKEntityType, EKEventStoreRequestAccessCompletionHandler)
        case contacts(CNContactsCompletionHandler)
        case pushNotifications(UNAuthorizationOptions, UNUserNotificationCenterCompletionHandler)
        
        var userContent: ContentType {
            switch self {
            case .camera: return .camera
            case .photosLibrary: return .photoLibrary
            case .calendar(let type, _): return .calendar(type)
            case .contacts: return .contacts
            case .pushNotifications(let options, _): return .pushNotifications(options)
            }
        }
    }
    
    private static var infoDictionary: [String: Any]? = {
        return Bundle.main.infoDictionary
    }()
    
    /// Returns the underlying authorization status for the requested content
    public static func authorizationStatus(for content: ContentType, completion: @escaping ((AuthorizationStatus) -> Void)) {
        checkPropertyListKey(for: content)
        
        switch content {
        case .camera:
            completion(.camera(AVCaptureDevice.authorizationStatus(for: .video)))
        case .photoLibrary:
            completion(.photoLibrary(PHPhotoLibrary.authorizationStatus()))
        case .calendar(let entityType):
            completion(.calendar(EKEventStore.authorizationStatus(for: entityType)))
        case .contacts:
            completion(.contacts(CNContactStore.authorizationStatus(for: .contacts)))
        case .pushNotifications(let options):
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                completion(.pushNotifications(settings, options))
            }
        }
    }
    
    /// "Converts" an authorization status to a simple bool
    public static func simpleAuthState(for authState: AuthorizationStatus) -> Bool {
        switch authState {
        case .camera(let status):
            return status == .authorized
        case .calendar(let status):
            return status == .authorized
        case .photoLibrary(let status):
            return status == .authorized
        case .contacts(let status):
            return status == .authorized
        case .pushNotifications(let settings, let options):
            let optionsAuthorized: Bool = {
                var authorized = false
                if options.contains(.badge) {
                    authorized = authorized || settings.badgeSetting == .enabled
                }
                if options.contains(.sound) {
                    authorized = authorized || settings.soundSetting == .enabled
                }
                if options.contains(.alert) {
                    authorized = authorized || settings.alertSetting == .enabled
                }
                if options.contains(.carPlay) {
                    authorized = authorized || settings.carPlaySetting == .enabled
                }
                if #available(iOS 12, *) {
                    if options.contains(.criticalAlert) {
                        authorized = authorized || settings.criticalAlertSetting == .enabled
                    }
                    if options.contains(.providesAppNotificationSettings) {
                        authorized = authorized || settings.providesAppNotificationSettings == true
                    }
                    if options.contains(.provisional) {
                        authorized = authorized || settings.providesAppNotificationSettings == true
                    }
                }
                return authorized
            }()
            return settings.authorizationStatus == .authorized && optionsAuthorized
        }
    }
    
    /// Returns a boolean value whether the specified content can be accessed
    public static func canAccess(_ content: ContentType, completion: @escaping ((Bool) -> Void)) {
        authorizationStatus(for: content) { status in
            completion(simpleAuthState(for: status))
        }
    }
    
    /// Requests access for the given content
    /// Calls isAuthorized on users behalf, no need to call it manually
    public static func requestAccess(for type: AuthorizationType) {
        checkPropertyListKey(for: type.userContent)
        
        canAccess(type.userContent) { isAuthorizedForContent in
            switch type {
            case .camera(let completion):
                isAuthorizedForContent ? completion(true) : AVCaptureDevice.requestAccess(for: .video, completionHandler: completion)
            case .photosLibrary(let completion):
                isAuthorizedForContent ? completion(.authorized) : PHPhotoLibrary.requestAuthorization(completion)
            case .calendar(let type, let completion):
                isAuthorizedForContent ? completion(true, nil) : EKEventStore().requestAccess(to: type, completion: completion)
            case .contacts(let completion):
                isAuthorizedForContent ? completion(true, nil) : CNContactStore().requestAccess(for: .contacts, completionHandler: completion)
            case .pushNotifications(let options, let completion):
                isAuthorizedForContent ? completion(true, nil) : UNUserNotificationCenter.current().requestAuthorization(options: options, completionHandler: completion)
            }
        }
    }
    
    /// Requests access for the specified content
    /// - Parameter content: The content that should be accessed
    /// - Parameter alertConfiguration: An alert configuration that will be used to show an alert in case the requested content can not be accessed, see the function `showAppSettingsAlert`
    /// - Parameter completion: A closure that will be called with a bool which tells whether the requested content can be accessed
    public static func requestAccess(for content: ContentType, alertConfiguration: AuthorizationAlertConfiguration? = nil, completion: @escaping SimpleAuthorizationCompletionHandler) {
        
        func complete(_ success: Bool) {
            if !success, let alertConfig = alertConfiguration {
                showAppSettingsAlert(with: alertConfig)
            }
            completion(success)
        }
        
        switch content {
        case .camera:
            requestAccess(for: .camera({ canAccess in
                complete(canAccess)
            }))
        case .photoLibrary:
            requestAccess(for: .photosLibrary({ authState in
                complete(Privacy.simpleAuthState(for: .photoLibrary(authState)))
            }))
        case .calendar(let type):
            requestAccess(for: .calendar(type, { (canAccess, error) in
                complete(canAccess && error == nil)
            }))
        case .contacts:
            requestAccess(for: .contacts({ (canAccess, error) in
                complete(canAccess && error == nil)
            }))
        case .pushNotifications(let options):
            requestAccess(for: .pushNotifications(options, { (canAccess, error) in
                complete(canAccess && error == nil)
            }))
        }
    }
    
    /// Shows an alert with an action to open the app settings
    /// - Parameter title:
    /// - Parameter message:
    /// - Parameter viewController: The viewController on which the alert will be presented
    public static func showAppSettingsAlert(with title: String, message: String, settingsTitle: String, cancelTitle: String, viewController: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
            let settingsURL = URL(string: UIApplication.openSettingsURLString)!
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        }))
        
        DispatchQueue.main.async {
            viewController.present(alert, animated: true, completion: nil)
            
        }
    }
    
    public static func showAppSettingsAlert(with config: AuthorizationAlertConfiguration) {
        showAppSettingsAlert(with: config.title,
                             message: config.message,
                             settingsTitle: config.showSettingsActionTitle,
                             cancelTitle: config.cancelTitle,
                             viewController: config.viewController)
    }
    
    private static func checkPropertyListKey(for type: ContentType) {
        guard let requiredKey = type.requiredInfoPlistKey else { return }
        precondition(Privacy.infoDictionary?[requiredKey] != nil, "The \(type.description) permission requires the Info.plist key \(requiredKey)")
    }
    
}
