---
description: Data persistence and storage rules for Teams, Activities, and FCM tokens
---

# Data Persistence Rules

## Teams & Activities (CSV in Firebase Storage)

- **Storage**: CSV files (`teams.csv`, `activities.csv`) in **Firebase Storage**
- **Logic**: `DataManager` coordinates `CSVService` (parsing) and `StorageService` (upload/download)
- **Sync**: Manager uploads on change; Team Member downloads on launch/refresh

> **CRITICAL**: NEVER migrate Teams/Activities to Firestore unless explicitly authorized.

### Activities CSV Format
```csv
id,name,description,memberName,priority,status,outcome,createdAt,deadline,startedAt,completedAt,manager
```

### Teams CSV Format
```csv
name,team,email,manager
```

## Notifications (Firestore)

- **Storage**: Firestore `fcmTokens` collection
- **Purpose**: FCM token lookup (not for functional data)
- **macOS**: Must manually retrieve token via `Messaging.messaging().token()` after APNs registration
