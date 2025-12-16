# Push Notifications Implementation Plan ✅ COMPLETED

## Overview
This document outlines the plan for implementing Firebase Cloud Messaging (FCM) push notifications in the valta app ecosystem, leveraging the existing Firebase integration.

## Current Firebase Setup
- ✅ FirebaseAuth (Anonymous Authentication)
- ✅ FirebaseStorage (CSV file storage)
- ✅ GCM enabled in GoogleService-Info.plist
- ✅ Two apps: `valta` (team member) and `valtaManager` (manager)
- ✅ FCM Token Storage (Firestore)
- ✅ Cloud Functions Deployments

## Notification Requirements

Based on `FULL_SPECIFICATION.md`, the following notifications are required:

### 1. Activity Assigned (Manager → Team Member)
**Trigger:** When manager creates and assigns a new activity  
**Recipient:** Assigned team member  
**Message Format:**
```
[Manager name] has assigned p[0/1/2/3] activity on [date, time] with deadline [date, time] to you, please start the activity: [Activity name].
```

### 2. Activity Started (Team Member → All Team Members)
**Trigger:** When team member starts an assigned activity  
**Recipient:** All team members in the same team  
**Message Format:**
```
[Team member name]'s p[0/1/2/3] activity has started on [date, time] with deadline [date, time] for [Activity name].
```

### 3. Completion Requested (Team Member → Manager)
**Trigger:** When team member requests completion approval  
**Recipient:** Manager  
**Message Format:**
```
[Team member name] has requested completion approval for p[0/1/2/3] activity "[Activity name]"
```

### 4. Activity Completed (Manager → All Team Members)
**Trigger:** When manager approves/completes an activity  
**Recipient:** All team members in the same team  
**Message Format:**
```
[Team member name]'s p[0/1/2/3] activity has completed [ahead/jit/overrun] with status [red/green/amber]
```

## Implementation Plan

### Phase 1: Firebase Cloud Messaging Setup

#### 1.1 Add Firebase Messaging SDK
- [x] Add `FirebaseMessaging` package via Swift Package Manager to both targets
- [x] Update `valta.xcodeproj` to include FirebaseMessaging dependency

#### 1.2 Configure App Capabilities
- [x] Enable Push Notifications capability in Xcode for both apps
- [x] Enable Background Modes → Remote notifications for both apps
- [x] Update entitlements files if needed

#### 1.3 Firebase Console Configuration
- [x] Upload APNs Authentication Key (.p8 file) to Firebase Console
  - Generate key in Apple Developer Portal
  - Upload to Firebase Console → Project Settings → Cloud Messaging → APNs Authentication Key
- [x] Configure APNs certificates (if using certificate-based auth instead)
- [x] Verify GCM Sender ID matches GoogleService-Info.plist

#### 1.4 Update AppDelegate
- [x] Implement `UNUserNotificationCenterDelegate` in AppDelegate
- [x] Request notification permissions
- [x] Handle notification registration
- [x] Handle foreground/background notification delivery
- [x] Handle notification taps/interactions

### Phase 2: FCM Token Management

#### 2.1 Create NotificationService
**File:** `Shared/Services/NotificationService.swift`

**Responsibilities:**
- Register for remote notifications
- Obtain and store FCM token
- Upload FCM token to Firebase (Firestore or Realtime Database)
- Map FCM tokens to user IDs (Firebase Auth UID)
- Handle token refresh

**Key Methods:**
```swift
- requestNotificationPermission() async -> Bool
- registerForRemoteNotifications()
- uploadFCMToken(_ token: String, userId: String)
- getFCMToken() -> String?
- subscribeToTeamNotifications(teamId: String)
```

#### 2.2 Token Storage Strategy
**Option A: Firestore (Recommended)**
- Collection: `fcmTokens`
- Document ID: User UID
- Fields: `token`, `updatedAt`, `appType` (valta/valtaManager)

**Option B: Realtime Database**
- Path: `/fcmTokens/{userId}`
- Structure: `{ token: string, updatedAt: timestamp, appType: string }`

**Option C: Firebase Storage (Current CSV approach)**
- Add `fcm_tokens.csv` file
- Less ideal for real-time lookups

**Recommendation:** Use Firestore for better real-time capabilities and easier querying.

### Phase 3: Notification Sending Infrastructure

#### 3.1 Create NotificationSender Service
**File:** `Shared/Services/NotificationSender.swift`

**Responsibilities:**
- Send notifications via Firebase Admin SDK (backend) OR
- Use Firebase Cloud Functions to send notifications
- Format notification messages according to spec
- Handle notification payload structure

**Note:** FCM requires server-side code (Node.js/Python/Go) to send notifications. Options:
1. **Firebase Cloud Functions** (Recommended - serverless, integrated)
2. **Standalone backend service** (Node.js/Python)
3. **Firebase Admin SDK** (requires server infrastructure)

#### 3.2 Notification Payload Structure
```json
{
  "notification": {
    "title": "Activity Update",
    "body": "[Formatted message per spec]"
  },
  "data": {
    "type": "activity_assigned|activity_started|completion_requested|activity_completed",
    "activityId": "uuid",
    "teamId": "uuid",
    "priority": "p0|p1|p2|p3",
    "status": "running|completed|..."
  },
  "apns": {
    "payload": {
      "aps": {
        "sound": "default",
        "badge": 1
      }
    }
  }
}
```

### Phase 4: Integration Points

#### 4.1 Activity Assignment (Manager App)
**File:** `valtaManager/AppState.swift` → `addActivity()`

**Changes:**
- After activity is added and synced, trigger notification
- Get assigned member's FCM token from Firestore
- Send notification via Cloud Function/backend

**Implementation:**
```swift
func addActivity(_ activity: Activity) {
    // ... existing code ...
    
    // After successful sync
    Task {
        await NotificationService.shared.sendActivityAssignedNotification(
            activity: activity,
            assignedTo: activity.assignedMember
        )
    }
}
```

#### 4.2 Activity Started (Team Member App)
**File:** `valta/TeamMemberAppState.swift` → `startActivity()`

**Changes:**
- After activity status changes to running, notify all team members
- Get all team members' FCM tokens
- Send notification to all team members

**Implementation:**
```swift
func startActivity(_ activity: Activity) {
    // ... existing code ...
    
    Task {
        await NotificationService.shared.sendActivityStartedNotification(
            activity: activity,
            team: team
        )
    }
}
```

#### 4.3 Completion Requested (Team Member App)
**File:** `valta/TeamMemberAppState.swift` → `requestReview()`

**Changes:**
- After status changes to managerPending, notify manager
- Get manager's FCM token
- Send notification

**Implementation:**
```swift
func requestReview(_ activity: Activity) {
    // ... existing code ...
    
    Task {
        await NotificationService.shared.sendCompletionRequestedNotification(
            activity: activity
        )
    }
}
```

#### 4.4 Activity Completed (Manager App)
**File:** `valtaManager/AppState.swift` → `approveCompletion()` and `completeActivity()`

**Changes:**
- After activity is completed, notify all team members
- Get all team members' FCM tokens
- Send notification with outcome information

**Implementation:**
```swift
func approveCompletion(_ activity: Activity) {
    // ... existing code ...
    
    Task {
        await NotificationService.shared.sendActivityCompletedNotification(
            activity: activity,
            team: team
        )
    }
}
```

### Phase 5: Firebase Cloud Functions (Backend)

#### 5.1 Setup Cloud Functions
**File:** `functions/index.js` (new directory)

**Required Functions:**
1. `sendActivityAssignedNotification` - HTTP callable function
2. `sendActivityStartedNotification` - HTTP callable function
3. `sendCompletionRequestedNotification` - HTTP callable function
4. `sendActivityCompletedNotification` - HTTP callable function

**Dependencies:**
```json
{
  "firebase-admin": "^12.0.0",
  "firebase-functions": "^4.5.0"
}
```

#### 5.2 Function Implementation Structure
```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.sendActivityAssignedNotification = functions.https.onCall(async (data, context) => {
  // Verify authentication
  // Get recipient FCM token
  // Format message
  // Send via admin.messaging().send()
});
```

#### 5.3 Security Rules
- Verify caller is authenticated
- Verify caller has permission to send notification
- Validate input data

### Phase 6: Notification Handling

#### 6.1 Foreground Notifications
- Display in-app notification banner
- Update UI state if needed
- Handle notification tap to navigate to relevant screen

#### 6.2 Background Notifications
- Update badge count
- Show notification banner
- Handle silent notifications for data sync

#### 6.3 Notification Actions (Optional)
- Quick actions: "View Activity", "Start Activity", "Approve"
- Requires notification categories and action buttons

### Phase 7: Testing & Validation

#### 7.1 Unit Tests
- [x] Test notification message formatting
- [x] Test FCM token management
- [x] Test notification service methods

#### 7.2 Integration Tests
- [x] Test notification sending from manager app
- [x] Test notification receiving in team member app
- [x] Test notification sending from team member app
- [x] Test notification receiving in manager app

#### 7.3 Manual Testing
- [x] Test on physical devices (iOS/macOS)
- [x] Test notification delivery in foreground
- [x] Test notification delivery in background
- [x] Test notification delivery when app is closed
- [x] Test notification tap handling
- [x] Test notification permissions flow

## File Structure

```
valta/
├── Shared/
│   ├── Services/
│   │   ├── NotificationService.swift          # NEW - FCM token management
│   │   └── NotificationSender.swift           # NEW - Notification sending logic
│   └── AppDelegate.swift                      # MODIFY - Add notification handling
├── valta/
│   └── valtaApp.swift                         # MODIFY - Initialize notification service
├── valtaManager/
│   └── valtaManagerApp.swift                  # MODIFY - Initialize notification service
└── functions/                                  # NEW - Cloud Functions directory
    ├── package.json
    ├── index.js
    └── .gitignore
```

## Dependencies to Add

### Swift Packages
- `FirebaseMessaging` (via Swift Package Manager)

### Cloud Functions
- `firebase-admin`
- `firebase-functions`

## Implementation Order

1. **Phase 1**: Firebase Cloud Messaging Setup
2. **Phase 2**: FCM Token Management
3. **Phase 5**: Firebase Cloud Functions (backend)
4. **Phase 3**: Notification Sending Infrastructure
5. **Phase 4**: Integration Points
6. **Phase 6**: Notification Handling
7. **Phase 7**: Testing & Validation

## Considerations

### macOS vs iOS
- macOS apps can receive push notifications but require:
  - App Sandbox enabled
  - Push Notifications capability
  - Proper entitlements
- Consider platform-specific notification handling

### Anonymous Authentication
- Current auth uses anonymous Firebase Auth
- FCM tokens will be associated with anonymous user UIDs
- Consider migration path if moving to named users later

### Data Storage
- Currently using Firebase Storage (CSV files)
- For FCM tokens, Firestore is recommended for real-time lookups
- May need to add Firestore dependency

### Notification Permissions
- Request permissions on app launch
- Handle permission denial gracefully
- Show in-app prompts explaining why notifications are needed

### Token Refresh
- FCM tokens can refresh periodically
- Implement token refresh listener
- Update stored tokens automatically

## Security Considerations

1. **Authentication**: Verify all Cloud Function callers are authenticated
2. **Authorization**: Ensure users can only send notifications to their team members
3. **Input Validation**: Validate all notification data before sending
4. **Rate Limiting**: Implement rate limiting in Cloud Functions
5. **Token Security**: Store FCM tokens securely, don't expose in client code

## Future Enhancements

1. **Notification Preferences**: Allow users to configure which notifications they receive
2. **Notification History**: Store notification history in Firestore
3. **Rich Notifications**: Add images, custom sounds, action buttons
4. **Notification Groups**: Group related notifications
5. **Quiet Hours**: Allow users to set quiet hours for notifications
6. **Notification Analytics**: Track notification delivery and engagement

## Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Firebase Cloud Functions Documentation](https://firebase.google.com/docs/functions)
- [Apple Push Notification Service](https://developer.apple.com/documentation/usernotifications)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
