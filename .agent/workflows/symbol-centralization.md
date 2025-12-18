---
description: Symbol string centralization rule for SF Symbols
---

# Symbol Centralization Rule

All SF Symbol strings must be defined in `AppSymbols.swift` and referenced through the `AppSymbols` enum. 

## Don't do this:
```swift
Image(systemName: "arrow.right")
Image(systemName: "checkmark.circle.fill")
```

## Do this instead:
```swift
// In AppSymbols.swift
static let arrowRight = "arrow.right"
static let completed = "checkmark.circle.fill"

// In your view
Image(symbol: AppSymbols.arrowRight)
Image(symbol: AppSymbols.completed)
```

## Why?
- Consistency across the codebase
- Easy refactoring if symbol names change
- Single source of truth for all icons
- Prevents typos in symbol names

## Exceptions
- Using variables/properties that already contain AppSymbols values (e.g., `status.icon`, parameter `icon`)
