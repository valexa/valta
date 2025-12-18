---
description: Testing framework rules using Swift Testing
---

# Testing Framework

## Framework

- **Use**: Swift Testing (`import Testing`)
- **Prohibited**: `XCTest` for unit tests

## Syntax

```swift
import Testing

struct MyTests {
    @Test
    func testExample() {
        #expect(result == expected)
    }
}
```

- Use `@Test` macro for test functions
- Use `#expect(...)` for assertions
- Use `struct` or `final class` for test suites
