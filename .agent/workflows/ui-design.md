---
description: UI and design system guidelines for macOS
---

# UI & Design System

## macOS Platform

- **Traffic Lights**: Content should extend to top edge where appropriate
- **Focus Rings**: Disable globally with `.focusEffectDisabled()`

## Components

- **Search**: Use native `.searchable` modifier
- **Buttons**: Use `CompletionButton` for standardized loading states

## Performance

Calculate expensive operations once:
```swift
// ✅ Correct
let outcome = activity.calculateOutcome()
Text(outcome.rawValue)
Image(outcome.icon)

// ❌ Incorrect (duplicate calculations)
Text(activity.calculateOutcome().rawValue)
Image(activity.calculateOutcome().icon)
```
