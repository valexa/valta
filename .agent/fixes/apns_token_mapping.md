# APNs Token Mapping Fix

## Description of the Problem
Push notifications were initially working on local debug builds, but they began silently dropping after subsequent FCM token refreshes.

The problem stemmed from a mismatch between the explicit App Entitlements (`aps-environment` = `development`) and Firebase's internal auto-detection logic for APNs environments. In `AppDelegate.swift`, the code mapped the APNs token directly to Firebase (`Messaging.messaging().apnsToken = deviceToken`), relying entirely on FCM to "auto-detect" if the session belonged to the Sandbox (development) or Production Apple gateways.

During a background FCM token refresh (as confirmed by the `updatedAt` field updating correctly in Firestore), Firebase's auto-detection often misidentified the token's origin, mapping a development APNs token as a production token. This caused Apple's APNs server to reject the payloads originating from the Firebase backend.

## The Fix

### 1. Hardcoding the Production Entitlement
We replaced the development values with `production` in both entitlements files to enforce Production APNs on any compiled archive:
- `valta/valta.entitlements`
- `valtaManager/valtaManager.entitlements`

### 2. Disabling FCM Auto-Detection
Instead of allowing Firebase to guess the environment, we updated the `AppDelegate.swift` registrations to dynamically instruct Firebase on the environment based on the local Xcode build phase using the `#if DEBUG` macro:

```swift
func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    #if DEBUG
    Messaging.messaging().setAPNSToken(deviceToken, type: .sandbox)
    #else
    Messaging.messaging().setAPNSToken(deviceToken, type: .prod)
    #endif
}
```

This prevents Firebase from mapping tokens to the wrong APNs gateway during background rotation!
