//
//  Definitions.swift
//  Consent
//
//  Created by Oliver Krakora on 23.01.19.
//  Copyright © 2019 Oliver Krakora. All rights reserved.
//

import Foundation
import AVKit
import Photos
import EventKit
import Contacts
import UserNotifications

// MARK: Definitions

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
