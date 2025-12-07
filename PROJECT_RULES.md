# Project Rules & Architectural Standards

This document outlines the critical rules, architectural decisions, and coding standards for the `valta` project. All future development must adhere to these guidelines to ensure consistency and prevent regressions.

## 1. Data Persistence Layer (CRITICAL)

The project uses a hybrid persistence strategy. This is a deliberate architectural decision.

### 1.1 Teams & Activities (Data)
*   **Storage**: CSV files (`teams.csv`, `activities.csv`) stored in **Firebase Storage**.
*   **Logic**: Managed by `DataManager`, which coordinates `CSVService` (parsing/serialization) and `StorageService` (upload/download).
*   **Rule**: **NEVER** migrate core data (Teams/Activities) to Firestore unless explicitly authorized by a major refactor plan.
*   **Sync**:
    *   *Manager*: Uploads CSV on every change.
    *   *Team Member*: Downloads CSV on app launch/refresh.

### 1.2 Notifications (FCM Tokens)
*   **Storage**: **Firestore** (`fcmTokens` collection).
*   **Logic**: Managed by `FirestoreService`.
*   **Rationale**: Firestore allows efficient looking up of individual user tokens without downloading a massive CSV file.
*   **Rule**: Firestore is **ONLY** for FCM tokens. Do not add functional data logic here.

---

## 2. State Management

*   **Framework**: **Observation** (`@Observable`).
*   **Prohibited**: Do NOT use `ObservableObject` or `@Published` (Combine).
*   **Initialization**: When initializing `@State` properties in a custom `init`, use the underscore syntax with `wrappedValue`:
    ```swift
    init(member: TeamMember?) {
        _memberFilter = State(wrappedValue: member) // ✅ Correct
        // _memberFilter = State(initialValue: member) // ❌ Incorrect
    }
    ```

### 2.1 Nested Mutations
*   **Problem**: Observation does not automatically detect changes within nested arrays or reference types.
*   **Solution**: You must explicitly trigger an update when modifying nested data in `DataManager`.
    ```swift
    // In DataManager
    func notifyTeamsChanged() {
        teams = teams // Triggers observers
        onTeamsChanged?()
    }
    ```

---

## 3. Data Synchronization & Mutation

### 3.1 The `updateInBackend` Pattern
*   All data mutations should go through `Activity.updateInBackend { ... }`.
*   **Responsibility**: This function applies the mutation, notifies observers immediately, AND triggers the background sync.
*   **Rule**: **NEVER** manually call `dataManager.syncActivities()` or `notifyTeamsChanged()` immediately after calling `updateInBackend`. It creates race conditions and redundant network calls.

    ```swift
    // ✅ Correct
    activity.updateInBackend { $0.status = .completed }
    
    // ❌ Incorrect (Redundant)
    activity.updateInBackend { $0.status = .completed }
    await dataManager.syncActivities() 
    ```

---

## 4. UI & Design System

### 4.1 macOS Platform
*   **Traffic Lights**: The sidebar and main window setup must respect macOS traffic lights. Content should extend to the top edge (`edgesIgnoringSafeArea(.top)` where appropriate) and avoid occlusion.
*   **Focus Rings**: System focus rings on buttons should be disabled globally (`.focusEffectDisabled()`) for a cleaner look.

### 4.2 Components
*   **Search**: Use the native SwiftUI `.searchable` modifier. Do not build custom search bars unless absolutely necessary.
*   **Buttons**: Use standardized button styles. Refactor common logic (loading states, etc.) into reusable components like `CompletionButton` rather than duplicating logic.

### 4.3 Performance
*   **Calculations**: Avoid redundant expensive calculations in `body`. Calculate once and store:
    ```swift
    // ✅ Correct
    let outcome = activity.calculateOutcome()
    Text(outcome.rawValue)
    Image(outcome.icon)
    
    // ❌ Incorrect
    Text(activity.calculateOutcome().rawValue)
    Image(activity.calculateOutcome().icon)
    ```

---

## 5. Coding Standards

*   **Async/Await**: Use Swift Concurrency (`Task`, `async/await`) over GCD (`DispatchQueue`).
*   **Models**: Data models (e.g., `Activity`) should be value types (`struct`) where possible to play nicely with Observation and simple mutation flows.
