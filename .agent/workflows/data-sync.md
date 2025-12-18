---
description: Data mutation pattern using updateInBackend
---

# Data Sync Pattern

## The `updateInBackend` Pattern

All Activity mutations must use `Activity.updateInBackend { ... }`:

```swift
// ✅ Correct
activity.updateInBackend { $0.status = .completed }

// ❌ Incorrect (redundant sync)
activity.updateInBackend { $0.status = .completed }
await dataManager.syncActivities() // DON'T DO THIS
```

## What It Does

1. Applies the mutation
2. Notifies observers immediately
3. Triggers background sync

> **NEVER** manually call `dataManager.syncActivities()` after `updateInBackend` - creates race conditions.
