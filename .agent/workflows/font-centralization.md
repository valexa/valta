---
description: Font centralization rule for consistent typography
---

# Font Centralization Rule

All fonts must be defined in `StyleGuideFonts.swift` using `AppFont` constants.

## Critical Rule: Always Use AppFont Constants

**Never construct fonts manually with `AppFontSize`** - always use the corresponding `AppFont` constant.

### ❌ Don't do this:
```swift
.font(.system(size: AppFontSize.headerLarge, weight: .bold))
.font(.system(size: AppFontSize.bodyStandard))
.font(.system(size: AppFontSize.caption, weight: .bold))
.font(.system(size: 14, weight: .semibold))
```

### ✅ Do this instead:
```swift
.font(AppFont.headerLarge)
.font(AppFont.bodyStandard)
.font(AppFont.captionBold)
.font(AppFont.bodyPrimary)
```

## AppFont Constants Reference

### Icons
| Constant | Size | Design |
|----------|------|--------|
| `iconXL` | 48pt | System default |
| `iconLarge` | 40pt | System default |

### Headers
| Constant | Size | Weight | Design |
|----------|------|--------|--------|
| `headerXL` | 32pt | Bold | Rounded |
| `headerLarge` | 26pt | Bold | Rounded |
| `headerLargeRegular` | 26pt | Regular | Default |
| `headerSection` | 22pt | Bold | Rounded |
| `headerSectionSemibold` | 22pt | Semibold | Rounded |

### Body Text (18pt - bodyLarge)
| Constant | Weight |
|----------|--------|
| `bodyLarge` | Regular |
| `bodyLargeSemibold` | Semibold |

### Body Text (14pt - bodyStandard)
| Constant | Weight |
|----------|--------|
| `bodyStandard` | Regular |
| `bodyStandardMedium` | Medium |
| `bodyStandardSemibold` | Semibold |
| `bodyPrimary` | Semibold |
| `bodyPrimaryMedium` | Medium |

### Body Text (12pt - bodySmall)
| Constant | Weight |
|----------|--------|
| `bodySmall` | Regular |
| `bodySmallMedium` | Medium |
| `bodySmallSemibold` | Semibold |

### Captions (10pt)
| Constant | Weight | Design |
|----------|--------|--------|
| `caption` | Regular | Default |
| `captionMedium` | Medium | Default |
| `captionSemibold` | Semibold | Default |
| `captionBold` | Bold | Default |
| `captionMonospaced` | Medium | Monospaced |

### Badges
| Constant | Weight | Design |
|----------|--------|--------|
| `badge` | Medium | Default |
| `badgeCompact` | Medium | Default |
| `priorityBadge` | Bold | Rounded |

### Buttons
| Constant | Size | Weight |
|----------|------|--------|
| `buttonLarge` | 18pt | Semibold |
| `buttonStandard` | 14pt | Semibold |
| `buttonSmall` | 10pt | Semibold |

### Stats
| Constant | Size | Weight | Design |
|----------|------|--------|--------|
| `statLarge` | 22pt | Bold | Rounded |
| `statMedium` | 14pt | Bold | Rounded |

## Conditional Font Weight

For dynamic fonts based on state, use conditional AppFont selection:

```swift
// ❌ Don't:
.font(.system(size: AppFontSize.bodyStandard, weight: isSelected ? .semibold : .medium))

// ✅ Do:
.font(isSelected ? AppFont.bodyStandardSemibold : AppFont.bodyStandardMedium)
```

## Adding New Fonts

If an `AppFont` doesn't exist for your use case:

1. Check if an existing constant matches your needs
2. If not, add a new constant to `StyleGuideFonts.swift`
3. Use an existing `AppFontSize` constant
4. Give it a descriptive name
