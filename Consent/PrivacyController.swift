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

public struct PrivacyController {
    
    // MARK: Definitions
    
    public typealias AVKitCompletionHandler = ((Bool) -> Void)
    
    public typealias PHKitCompletionHandler = ((PHAuthorizationStatus) -> Void)
    
    public typealias CNContactsCompletionHandler = ((Bool, Error?) -> Void)
    
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
    
    public enum UserContent {
        case camera
        case photosLibrary
        case calendar(EKEntityType)
        case contacts
        
        public var requiredInfoPlistKey: String {
            switch self {
            case .camera: return "NSCameraUsageDescription"
            case .photosLibrary: return "NSPhotoLibraryUsageDescription"
            case .calendar: return "NSCalendarsUsageDescription"
            case .contacts: return "NSContactsUsageDescription"
            }
        }
        
        public var description: String {
            switch self {
            case .camera: return "camera"
            case .photosLibrary: return "photos library"
            case .calendar: return "calendar"
            case .contacts: return "contacts"
            }
        }
    }
    
    public enum AuthorizationStatus {
        case camera(AVAuthorizationStatus)
        case photosLibrary(PHAuthorizationStatus)
        case calendar(EKAuthorizationStatus)
        case contacts(CNAuthorizationStatus)
    }
    
    public enum AuthorizationCompletionHandler {
        case camera(AVKitCompletionHandler)
        case photosLibrary(PHKitCompletionHandler)
        case calendar(EKEventStoreRequestAccessCompletionHandler)
        case contacts(CNContactsCompletionHandler)
    }
    
    private static var infoDictionary: [String: Any]? = {
        return Bundle.main.infoDictionary
    }()
    
    /// Returns the underlying authorization status for the requested content
    public static func authorizationStatus(for content: UserContent) -> AuthorizationStatus {
        precondition(PrivacyController.infoDictionary?[content.requiredInfoPlistKey] != nil, "The \(content.description) permission requires the Info.plist key \(content.requiredInfoPlistKey)")
        
        switch content {
        case .camera:
            return .camera(AVCaptureDevice.authorizationStatus(for: .video))
        case .photosLibrary:
            return .photosLibrary(PHPhotoLibrary.authorizationStatus())
        case .calendar(let entityType):
            return .calendar(EKEventStore.authorizationStatus(for: entityType))
        case .contacts:
            return .contacts(CNContactStore.authorizationStatus(for: .contacts))
        }
    }
    
    /// "Converts" an authorization status to a simple bool
    public static func simpleAuthState(for authState: AuthorizationStatus) -> Bool {
        switch authState {
        case .camera(let status):
            return status == .authorized
        case .calendar(let status):
            return status == .authorized
        case .photosLibrary(let status):
            return status == .authorized
        case .contacts(let status):
            return status == .authorized
        }
    }
    
    /// Returns a boolean value whether the specified content can be accessed
    public static func canAccess(_ content: UserContent) -> Bool {
        let authState = authorizationStatus(for: content)
        return simpleAuthState(for: authState)
    }
    
    /// Requests access for the given content
    /// Calls isAuthorized on users behalf, no need to call it manually
    public static func requestAccess(for content: UserContent, completion: AuthorizationCompletionHandler) {
        precondition(PrivacyController.infoDictionary?[content.requiredInfoPlistKey] != nil,
                     "The \(content.description) permission requires the Info.plist key \(content.requiredInfoPlistKey)")
        
        let isAuthorizedForContent = canAccess(content)
        
        switch (content, completion) {
        case (.camera, .camera(let completion)):
            isAuthorizedForContent ? completion(true) : AVCaptureDevice.requestAccess(for: .video, completionHandler: completion)
        case (.photosLibrary, .photosLibrary(let completion)):
            isAuthorizedForContent ? completion(.authorized) : PHPhotoLibrary.requestAuthorization(completion)
        case (.calendar(let type), .calendar(let completion)):
            isAuthorizedForContent ? completion(true, nil) : EKEventStore().requestAccess(to: type, completion: completion)
        case (.contacts, .contacts(let completion)):
            isAuthorizedForContent ? completion(true, nil) : CNContactStore().requestAccess(for: .contacts, completionHandler: completion)
        default: break
        }
    }
    
    /// Requests access for the specified content
    /// - Parameter content: The content that should be accessed
    /// - Parameter alertConfiguration: An alert configuration that will be used to show an alert in case the requested content can not be accessed, see the function `showAppSettingsAlert`
    /// - Parameter completion: A closure that will be called with a bool which tells whether the requested content can be accessed
    public static func requestAccess(for content: UserContent, alertConfiguration: AuthorizationAlertConfiguration? = nil, completion: @escaping SimpleAuthorizationCompletionHandler) {
        
        func complete(success: Bool) {
            if !success, let alertConfig = alertConfiguration {
                showAppSettingsAlert(with: alertConfig)
            }
            completion(success)
        }
        
        switch content {
        case .camera:
            requestAccess(for: content, completion: .camera({ success in
                complete(success: success)
            }))
        case .photosLibrary:
            requestAccess(for: content, completion: .photosLibrary({ (status) in
                complete(success: PrivacyController.simpleAuthState(for: .photosLibrary(status)))
            }))
        case .calendar:
            requestAccess(for: content, completion: .calendar({ (canAccess, error) in
                complete(success: canAccess && error == nil)
            }))
        case .contacts:
            requestAccess(for: content, completion: .contacts({ (canAccess, error) in
                complete(success: canAccess && error == nil)
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
    
}