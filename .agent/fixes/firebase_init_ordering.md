# Firebase Initialization Ordering & Service Deferral

## The Problem

SwiftUI `App` structs initialize their `@State` properties (including service singletons like `DataManager.shared` or `NotificationService.shared`) when the `App` struct is instantiated. This occurs **before** `AppDelegate.applicationDidFinishLaunching` is called.

If these services access Firebase singletons (e.g., `Messaging.messaging()`, `Firestore.firestore()`, `Functions.functions()`) during their `init()`, the app will crash with an "unconfigured" error because `FirebaseApp.configure()` hasn't run yet.

## The Solution: Orchestrated Initialization

To ensure absolute stability and prevent startup crashes across different machines and network environments, we use a three-tiered approach: **Signaling**, **Gating**, and **Guarding**.

### 1. The AppOrchestrator (Signaling)

We use a central `AppOrchestrator` to manage the "Firebase Ready" state. This ensures that no component attempts to use Firebase before it is configured.

```swift
@Observable
final class AppOrchestrator {
    static let shared = AppOrchestrator()
    private(set) var isFirebaseReady = false
    
    @MainActor
    func configureFirebase() {
        guard !isFirebaseReady else { return }
        FirebaseApp.configure()
        isFirebaseReady = true
    }
}
```

### 2. The App Struct (Gating)

We gate the main UI and startup tasks behind the orchestrator's readiness flag. This prevents `.task` modifiers from running premature data loads.

```swift
struct valtaApp: App {
    @State private var orchestrator = AppOrchestrator.shared

    var body: some Scene {
        WindowGroup {
            if orchestrator.isFirebaseReady {
                ContentView()
                    .task { /* Data loading logic here */ }
            } else {
                ProgressView() // Show loading state until Firebase is ready
            }
        }
    }
}
```

### 3. Service Guards (Guarding)

Even with gating, we add defensive guards to all shared services to prevent crashes if a developer accidentally accesses them before initialization is complete.

```swift
func someServiceMethod() {
    // Check if Firebase is ready before using any Firebase component
    guard FirebaseApp.app() != nil else {
        print("⚠️ Service: Skipping - Firebase not ready")
        return
    }
    // Access Messaging, Auth, or Firestore here...
}
```

## Critical Implementation Details

### AppDelegate Coordination

The `AppDelegate` remains the source of truth for the configuration timing:

```swift
func applicationDidFinishLaunching(_ notification: Notification) {
    // 1. Initialize Firebase via the Orchestrator
    AppOrchestrator.shared.configureFirebase()
    
    // 2. Setup delegates after Firebase is ready
    NotificationService.shared.setup()
}
```

### Token Registration Race Condition

A common crash point is `Messaging.messaging().setAPNSToken`. This callback can fire extremely early (sometimes even before `applicationDidFinishLaunching` completes if the token is cached). **Always guard it:**

```swift
func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    guard FirebaseApp.app() != nil else { return } // Essential guard
    Messaging.messaging().setAPNSToken(deviceToken, type: .prod)
}
```

## Why not use App.init()?

While calling `FirebaseApp.configure()` in the `App` struct's `init()` might seem like an easy fix, it has significant downsides:
1. **Timing**: `App.init()` still doesn't guarantee execution before all `@State` properties are initialized in complex hierarchies.
2. **Framework Readiness**: `applicationDidFinishLaunching` ensures that the underlying AppKit/UIKit infrastructure is fully ready for the network and background tasks that Firebase starts.

## Sandbox and Environment Notes

### Avoid `NSApplicationCrashOnExceptions`
Do NOT use `NSApplicationCrashOnExceptions` in production. This turns non-fatal Objective-C exceptions (which many SDKs use internally) into hard crashes, especially dangerous with VPNs or strict Sandboxing.

### Sandbox Entitlements
Firebase requires outgoing network connections. Ensure the following are in your `.entitlements` file:
- `com.apple.security.app-sandbox`: `true`
- `com.apple.security.network.client`: `true`
- `com.apple.security.network.server`: `true` (if receiving push notifications)

