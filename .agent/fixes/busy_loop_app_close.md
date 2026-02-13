# Fix: Slow App Closing & gRPC Shutdown Timeouts

## Issue 1: Busy Loop on Close
**Symptoms:** The app exhibited a significant delay and stuttering animation when closing the main window or quitting.

**Root Cause:**
A background task in `valtaApp.swift` and `valtaManagerApp.swift` contained a `while true` loop for periodic data refreshing. Inside this loop, `try? await Task.sleep(...)` was used. When the app or window closes, `CancellationError` was swallowed by `try?`, causing a tight busy loop that consumed main thread resources.

**Fix:**
Removed `try?` from `Task.sleep` and added explicit `CancellationError` handling to break the loop immediately upon cancellation.

```swift
// After
while true {
    try await Task.sleep(nanoseconds: 60 * 1_000_000_000)
    await dataManager.loadData()
}
```

## Issue 2: Translucent Window Glitch & gRPC Timeouts
**Symptoms:**
1. **Visual Glitch:** The window became translucent and stuttered during the closing animation.
2. **Console Error:** `grpc_wait_for_shutdown_with_timeout() timed out` appeared in logs.

**Root Cause:**
`applicationShouldTerminateAfterLastWindowClosed` returned `true`, causing the process to terminate immediately while the window close animation was still active. This premature termination cut off the renderer (causing visual artifacts) and didn't give Firebase/gRPC enough time to close network connections (causing timeouts).

**Fix:**
Modified `AppDelegate.swift` to implement a "Graceful Delayed Termination":
1. Return `false` in `applicationShouldTerminateAfterLastWindowClosed` to prevent immediate OS killing.
2. Start a background `Task` that:
   - Waits 0.5s for the window animation to complete.
   - Calls `try? await Firestore.firestore().terminate()` to cleanly close gRPC channels.
   - Manually quits the app via `NSApplication.shared.terminate(nil)`.

```swift
func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Prevent immediate termination to allow animation to finish and gRPC to close
    Task {
        // Wait for window animation (0.5s)
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Clean up Firestore to prevent gRPC timeout
        try? await Firestore.firestore().terminate()
        
        // Quit the app gracefully
        NSApplication.shared.terminate(nil)
    }
    return false
}
```
