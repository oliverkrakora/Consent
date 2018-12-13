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

// MARK: Definitions

    /// A protocol for handling authorization failures
    public protocol AuthorizationFailureHandler {
        func handleAuthorizationFailure(for contentType: ContentType)
    }

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
                showAppSettingsAlert(with: title,
                                     message: message,
                                     cancelActionTitle: cancelActionTitle,
                                     settingsActionTitle: showSettingsActionTitle,
                                     vc: viewController)
        }
    }

    public protocol PreconsentHandler {
        func handlePreconsent(for contentType: ContentType, consentCompletion: @escaping (() -> Void))
    }

    public struct PreconsentAlertHandler: PreconsentHandler {
        let title: String
        let message: String
        let consentTitle: String
        let denyTitle: String
        let viewController: UIViewController
        
        public init(title: String, message: String, allowActionTitle: String = "Settings", denyActionTitle: String = "Ok", vc: UIViewController) {
            self.title = title
            self.message = message
            self.consentTitle = allowActionTitle
            self.denyTitle = denyActionTitle
            self.viewController = vc
        }
    
        public func handlePreconsent(for contentType: ContentType, consentCompletion: @escaping (() -> Void)) {
            let alertVC = alert(with: title, message: message, actionTitle: consentTitle, cancelTitle: denyTitle) {
                consentCompletion()
            }
            viewController.present(alertVC, animated: true, completion: nil)
        }
    }

    public typealias AVKitCompletionHandler = ((Bool) -> Void)
    
    public typealias PHKitCompletionHandler = ((PHAuthorizationStatus) -> Void)
    
    public typealias CNContactsCompletionHandler = ((Bool, Error?) -> Void)
    
    public typealias UNUserNotificationCenterCompletionHandler = ((Bool, Error?) -> Void)
    
    public typealias SimpleAuthorizationCompletionHandler = ((Bool) -> Void)

    /// Content types for which a authorization request can be performed
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
    
    /// A request to access user content
    public enum AuthorizationRequest {
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
    
    /// Reflects the authorization status of all underlying apis
    public enum AuthorizationStatus {
        case camera(AVAuthorizationStatus)
        case photoLibrary(PHAuthorizationStatus)
        case calendar(EKAuthorizationStatus)
        case contacts(CNAuthorizationStatus)
        case pushNotifications(UNNotificationSettings, UNAuthorizationOptions)
    }
    
    private var infoDictionary: [String: Any]? = {
        return Bundle.main.infoDictionary
    }()
    
    /// Returns the underlying authorization status for the requested content
    public func authorizationStatus(for content: ContentType, completion: @escaping ((AuthorizationStatus) -> Void)) {
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
    public func simpleAuthState(for authState: AuthorizationStatus) -> Bool {
        switch authState {
        case .camera(let status):
            return status == .authorized
        case .calendar(let status):
            return status == .authorized
        case .photoLibrary(let status):
            return status == .authorized
        case .contacts(let status):
            return status == .authorized
        // Sending push notifications are considered as authorized if at least the badge option is authorized
        case .pushNotifications(let settings, _):
            return settings.authorizationStatus == .authorized
        }
    }
    
    /// Checks the current authentication state for a given content and calls the completion closure whether the content can be accessed or not
    public func canAccess(_ content: ContentType, completion: @escaping ((Bool) -> Void)) {
        authorizationStatus(for: content) { status in
            completion(simpleAuthState(for: status))
        }
    }
    
    /// Requests access for the given content
    /// Calls isAuthorized on users behalf, no need to call it manually
    public func requestAccess(with request: AuthorizationRequest) {
        checkPropertyListKey(for: request.userContent)
        
        canAccess(request.userContent) { isAuthorizedForContent in
            switch request {
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
    public func requestAccess(for content: ContentType, preconsentHandler: PreconsentHandler? = nil, failureHandler: AuthorizationFailureHandler? = nil, completion: SimpleAuthorizationCompletionHandler?) {
        
        func complete(_ success: Bool) {
            if !success, let handler = failureHandler {
                handler.handleAuthorizationFailure(for: content)
            } else {
                completion?(success)
            }
        }
        
        func performAccessRequest() {
            switch content {
            case .camera:
                requestAccess(with: .camera({ canAccess in
                    complete(canAccess)
                }))
            case .photoLibrary:
                requestAccess(with: .photosLibrary({ authState in
                    complete(Consent.simpleAuthState(for: .photoLibrary(authState)))
                }))
            case .calendar(let type):
                requestAccess(with: .calendar(type, { (canAccess, error) in
                    complete(canAccess && error == nil)
                }))
            case .contacts:
                requestAccess(with: .contacts({ (canAccess, error) in
                    complete(canAccess && error == nil)
                }))
            case .pushNotifications(let options):
                requestAccess(with: .pushNotifications(options, { (canAccess, error) in
                    complete(canAccess && error == nil)
                }))
            }
        }

        if let handler = preconsentHandler {
            handler.handlePreconsent(for: content) {
                performAccessRequest()
            }
        } else {
            performAccessRequest()
        }
    }

    public func showAppSettingsAlert(with title: String, message: String, cancelActionTitle: String, settingsActionTitle: String, vc: UIViewController) {
        let alertVC =  alert(with: title, message: message, actionTitle: settingsActionTitle, cancelTitle: cancelActionTitle) {
            let settingsURL = URL(string: UIApplication.openSettingsURLString)!
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        }
        vc.present(alertVC, animated: true, completion: nil)
    }

    private func checkPropertyListKey(for type: ContentType) {
        guard let requiredKey = type.requiredInfoPlistKey else { return }
        precondition(Consent.infoDictionary?[requiredKey] != nil, "The \(type.description) permission requires the Info.plist key \(requiredKey)")
    }

    private func alert(with title: String, message: String, actionTitle: String, cancelTitle: String, cancelAction: (() -> Void)? = nil, action: @escaping (() -> Void)) -> UIViewController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel) { _ in
            cancelAction?()
        })
        alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { _ in
            action()
        }))
        return alert
    }
