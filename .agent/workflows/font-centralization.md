---
description: Font centralization rule for consistent typography
---

# Font Centralization Rule

All fonts must be defined in `StyleGuideFonts.swift` using `AppFont` or `AppFontSize`.

## Don't do this:
```swift
.font(.system(size: 14, weight: .semibold))
.font(.system(size: 11))
```

## Do this instead:
```swift
// Use predefined AppFont
.font(AppFont.bodyPrimary)
.font(AppFont.caption)

// Or use AppFontSize with custom weights if needed
.font(.system(size: AppFontSize.bodyStandard, weight: .medium))
```

## AppFontSize Scale (8 values)

| Size | Constant | Usage |
|------|----------|-------|
| 48pt | `iconXL` | Extra large icons |
| 40pt | `iconLarge` | Large icons |
| 32pt | `headerXL` | Onboarding headers |
| 26pt | `headerLarge` | Large headers |
| 22pt | `headerSection` | Section headers, page titles |
| 18pt | `bodyLarge` | Large body, subtitles |
| 14pt | `bodyStandard` | Standard body, primary content |
| 10pt | `caption` | Captions, small labels |

## Adding New Fonts

If an AppFont doesn't exist, add to `StyleGuideFonts.swift`:
1. Use an existing `AppFontSize` constant
2. Add a descriptive `AppFont` entry with weight/design
