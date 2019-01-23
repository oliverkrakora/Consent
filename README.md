# Consent

Ask users for their consent with just a single line of code.

### Without "Consent"
```
let authorizationState = AVCaptureDevice.authorizationStatus(for: .video)

switch authorizationState {
case .authorized:
//Show camera
case .denied:
// Handle error
case .notDetermined:
AVCaptureDevice.requestAccess(for: .video) { canAccess in
//Show camera
}
case .restricted:
}
```

### With Consent
```
Consent.requestAccess(for: .camera) { canAccess in
    if canAccess {
        //Show camera
    } else {
        // Handle failure
    }
}
```

### Carthage
`github oliverkrakora/Consent `

### Features

#### Enforced presence of the required Info.plist keys
Consent checks if the required Info.plist keys are present before performing any authorization related actions.

#### Automatic error handling
In case the user denies your request or the privacy settings have been changed afterwards you can navigate the user automatically to your apps settings.
You just need to create a `AuthorizationFailureAlertConfiguration` and pass it to the request access function.

If you want to show an alert which allows the user to navigate to your app settings, you just need to specify an `AuthorizationFailureAlertConfiguration` like this:

``` 
let failureHandler: AuthorizationFailureHandler = Consent.AuthorizationFailureAlertHandler(title: title, message: message, vc: vc)

Consent.requestAccess(for: content, failureHandler: failureHandler) { canAccess in
print("can access \(content.description): \(canAccess)")
}
```

#### Preconsent
You can also pass a `PreconsentHandler` to the requestAccess function where you can perform any kind of action before the system dialog will be shown.

``` 
let preconsentHandler: PreconsentHandler = Consent.PreconsentAlertHandler(title: title, message: message, vc: vc)

Consent.requestAccess(for: content, preconsentHandler: preconsentHandler) { canAccess in
print("can access \(content.description): \(canAccess)")
}
```
In this case a alert dialog will be shown asking the user if he wants to give permissions, if the user denies the system dialog will not be shown.

#### More control with specific errors
If you want a more specific error if the authorazation fails, you can use the following method:

```
Consent.requestAccess(with: .photosLibrary({ status in
    switch status {
        //...
    }
}))
```

