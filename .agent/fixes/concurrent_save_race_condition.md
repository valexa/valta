---
description: Fix data loss when two members save activities simultaneously
---

# Concurrent Save Race Condition Fix

## Problem

When two team members save activity data at the same time, the second writer silently overwrites the first's changes. `syncActivities()` serializes the entire local `activities` array and does a blind `PUT` to `activities.csv` in Firebase Storage — last writer wins.

```
Member A: load(v1) → mutate → upload(v1 + A's change)
Member B: load(v1) → mutate → upload(v1 + B's change)  ← A's change lost
```

## Solution: Timestamp Guard (Read-Before-Write)

Before uploading, check Firebase Storage metadata to see if `activities.csv` was modified since our last download. If so, re-download the fresh CSV, merge local mutations by activity ID, then upload.

### How it works

1. `StorageService` tracks `lastKnownRemoteTimestamp` — set after every download/upload
2. Before each upload, `hasRemoteConflict()` compares remote metadata timestamp vs local
3. On conflict: re-download → re-parse → merge pending mutations by ID → upload merged result
4. `pendingMutations` array in `DataManager` tracks which activities were locally mutated

### Files changed

- **`Shared/Services/StorageService.swift`** — Added `fetchMetadata` to protocol, `lastKnownRemoteTimestamp`, `downloadActivitiesWithTimestamp()`, `hasRemoteConflict()`
- **`Shared/Services/DataManager.swift`** — Added `pendingMutations`, conflict detection in `syncActivities()`, `mergeActivity(_:into:)`, `updateLocalState(with:parsedMembers:)`
- **`Shared/Extensions/Activity+Extension.swift`** — `updateInBackend` now appends mutated activity to `pendingMutations`
- **`valtaTests/MockStorageProvider.swift`** — Added `fetchMetadata` conformance with controllable `mockTimestamp`

### Merge strategy

Merge is per-activity by UUID. On conflict, each locally-mutated activity replaces its counterpart in the freshly-downloaded remote data. New activities (not in remote) are appended.

### Residual risk

Small timing window between `hasRemoteConflict()` check and the actual upload. Acceptable for a team activity app — Firestore atomic versioning (Plan B) would eliminate this entirely but adds complexity.
