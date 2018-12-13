# Consent

Ask users for permissions to access the device camera or any other content type with just a single line of code.

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
```Consent.requestAccess(for: .camera) { canAccess in
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
Consent checks if the required Info.plist keys are present before performing any authorization related actions

#### Automatic error handling
If you want to show an alert which allows the user to navigate to your app settings, you just need to specify an `AuthorizationFailureAlertConfiguration` like this:

``` let alertConfig = AuthorizationFailureAlertConfiguration(title: "Access requried",
message: "Please allow access to xyz",
showSettingsTitle: "Settings",
cancelTitle: "Cancel",
vc: self)
Consent.requestAccess(for: .camera, alertConfiguration: alertConfig) { isAuthorized in
// Your code goes here
}
```

#### More control with specific errors
If you want a more specific error if the authorazation fails, you can use the following method:

```Consent.requestAccess(with: .photosLibrary({ status in
    switch status {
        //...
    }
}))
```

