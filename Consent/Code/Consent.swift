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

private var infoDictionary: [String: Any]? = {
    return Bundle.main.infoDictionary
}()

/// Returns the underlying authorization status for the requested content
/// - Parameter content: The ContentType of which the status should be determined
/// - Parameter completion: The closure that will be called with the `AuthorizationStatus` for the requested content
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

/// Turns a AuthorizationStatus to a Bool
/// - Returns: true if the Authorization status reflects an `.authorized` state false otherwise
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

/// Tells if your application can access the specified content
public func isAuthorized(for content: ContentType, completion: @escaping ((Bool) -> Void)) {
    authorizationStatus(for: content) { status in
        completion(simpleAuthState(for: status))
    }
}

/// Requests access for the given content.
///
/// This functions also checks if the `ContentType` in the request can already be accessed and returns immediately if that is the case
public func requestAccess(with request: AuthorizationRequest) {
    checkPropertyListKey(for: request.userContent)
    
    isAuthorized(for: request.userContent) { isAuthorizedForContent in
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
/// - Parameter failureHandler: A protocol that can be adopted to handle errors e.g to display an alert
/// - Parameter preconsentHandler: A protocol that can be adopted to ask the user for consent before the system dialog is shown
/// - Parameter completion: A closure that will be called with a bool which tells whether the requested content can be accessed
public func requestAccess(for content: ContentType, preconsentHandler: PreconsentHandler? = nil, failureHandler: AuthorizationFailureHandler? = nil, completion: SimpleAuthorizationCompletionHandler?) {
    
    func complete(_ success: Bool) {
        if !success, let handler = failureHandler {
            DispatchQueue.main.async {
                handler.handleAuthorizationFailure(for: content)
            }
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
        DispatchQueue.main.async {
            handler.handlePreconsent(for: content) {
                performAccessRequest()
            }
        }
    } else {
        performAccessRequest()
    }
}

/// Checks if the required key for the `ContentType` is in the Info.plist.
private func checkPropertyListKey(for type: ContentType) {
    guard let requiredKey = type.requiredInfoPlistKey else { return }
    precondition(Consent.infoDictionary?[requiredKey] != nil, "The \(type.description) permission requires the Info.plist key \(requiredKey)")
}
