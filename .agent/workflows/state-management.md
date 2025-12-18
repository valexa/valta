---
description: State management rules using Observation framework
---

# State Management Rules

## Framework

- **Use**: `@Observable` (Observation framework)
- **Prohibited**: `ObservableObject`, `@Published` (Combine)

## @State Initialization

Use underscore syntax with `wrappedValue`:
```swift
init(member: TeamMember?) {
    _memberFilter = State(wrappedValue: member) // ✅ Correct
    // _memberFilter = State(initialValue: member) // ❌ Incorrect
}
```

## Nested Mutations

Observation doesn't detect changes in nested arrays. Explicitly trigger:
```swift
func notifyTeamsChanged() {
    teams = teams // Triggers observers
    onTeamsChanged?()
}
```
