# Push Notifications Setup Guide

This guide walks you through the remaining manual steps needed to complete the push notifications implementation.

## ✅ Completed Automatically

The following has been implemented in code:
- ✅ NotificationService for FCM token management
- ✅ NotificationSender for sending notifications via Cloud Functions
- ✅ AppDelegate updated with notification handling
- ✅ Integration into activity flows (assign, start, request, complete)
- ✅ App entry points updated to initialize notification service

## 📋 Manual Setup Steps

### 1. Add FirebaseMessaging SDK

1. Open `valta.xcodeproj` in Xcode
2. Select the project in the navigator
3. Go to **Package Dependencies** tab
4. Click the **+** button
5. Add Firebase iOS SDK if not already added:
   - URL: `https://github.com/firebase/firebase-ios-sdk`
   - Version: Latest
6. Add `FirebaseMessaging` product to both targets:
   - `valta` target
   - `valtaManager` target

### 2. Add FirebaseFunctions SDK

1. In the same Package Dependencies, add `FirebaseFunctions` product to both targets
2. This is needed for `NotificationSender` to call Cloud Functions

### 3. Configure App Capabilities

#### For both `valta` and `valtaManager` targets:

1. Select the target in Xcode
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **Push Notifications**
5. Add **Background Modes** and enable:
   - ✅ Remote notifications

### 4. Update Entitlements

The entitlements files should automatically include push notifications capability. Verify:
- `valta/valta.entitlements`
- `valtaManager/valtaManager.entitlements`

### 5. Firebase Console Configuration

#### 5.1 Enable Cloud Messaging

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `valta-a397c`
3. Go to **Project Settings** → **Cloud Messaging** tab

#### 5.2 Configure APNs (Apple Push Notification Service)

**Option A: APNs Authentication Key (Recommended)**

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list)
2. Create a new key with **Apple Push Notifications service (APNs)** enabled
3. Download the `.p8` key file
4. Note the **Key ID** and **Team ID**
5. In Firebase Console → **Cloud Messaging** → **APNs Authentication Key**:
   - Upload the `.p8` file
   - Enter Key ID
   - Enter Team ID

**Option B: APNs Certificates (Legacy)**

1. Create APNs certificates in Apple Developer Portal
2. Upload to Firebase Console → **Cloud Messaging** → **APNs Certificates**

#### 5.3 Verify Configuration

- GCM Sender ID should match: `677705210074` (from GoogleService-Info.plist)
- APNs should show as configured

### 6. Setup Firebase Cloud Functions

#### 6.1 Initialize Functions

```bash
# In project root
cd functions
npm init -y
npm install firebase-admin firebase-functions
```

#### 6.2 Create `functions/index.js`

See `functions/index.js` template in this project.

#### 6.3 Deploy Functions

```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase (if not already done)
firebase init functions

# Deploy functions
firebase deploy --only functions
```

### 7. Setup Firestore (Optional but Recommended)

For storing FCM tokens, Firestore is recommended over CSV:

1. In Firebase Console, enable **Firestore Database**
2. Create database in **production mode** (or test mode for development)
3. Update `NotificationService.uploadFCMToken()` to use Firestore:

```swift
import FirebaseFirestore

private func uploadFCMToken(_ token: String, userId: String) async {
    let db = Firestore.firestore()
    let tokenData: [String: Any] = [
        "token": token,
        "updatedAt": Timestamp(date: Date()),
        "appType": Bundle.main.bundleIdentifier?.contains("Manager") == true ? "valtaManager" : "valta"
    ]
    
    do {
        try await db.collection("fcmTokens").document(userId).setData(tokenData, merge: true)
        print("✅ FCM token uploaded to Firestore")
    } catch {
        print("❌ Error uploading FCM token: \(error.localizedDescription)")
    }
}
```

4. Add `FirebaseFirestore` package dependency in Xcode

### 8. Test Notifications

#### 8.1 Test from Firebase Console

1. Go to Firebase Console → **Cloud Messaging**
2. Click **Send test message**
3. Enter FCM token (from app logs)
4. Send test notification

#### 8.2 Test from App

1. Run the app
2. Grant notification permissions when prompted
3. Check console logs for FCM token
4. Trigger an activity action (assign, start, etc.)
5. Verify notification is received

## 🔍 Troubleshooting

### FCM Token Not Received

- Check that notification permissions are granted
- Verify APNs is configured in Firebase Console
- Check device is connected to internet
- Review console logs for errors

### Notifications Not Received

- Verify Cloud Functions are deployed
- Check Cloud Functions logs in Firebase Console
- Ensure FCM tokens are stored correctly
- Verify notification payload format

### Build Errors

- Ensure `FirebaseMessaging` and `FirebaseFunctions` are added to both targets
- Check that imports are correct
- Verify entitlements are configured

## 📝 Next Steps

After completing setup:

1. **Test all notification types:**
   - Activity assigned
   - Activity started
   - Completion requested
   - Activity completed

2. **Enhance notifications:**
   - Add notification actions (buttons)
   - Add rich notifications (images)
   - Implement notification history

3. **Monitor:**
   - Set up Firebase Analytics for notification metrics
   - Monitor Cloud Functions usage
   - Track notification delivery rates

## 📚 Resources

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [Firebase Cloud Functions Docs](https://firebase.google.com/docs/functions)
- [Apple Push Notifications](https://developer.apple.com/documentation/usernotifications)
