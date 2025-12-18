---
description: Coding standards and SwiftLint configuration
---

# Coding Standards

## Async/Await

Use Swift Concurrency (`Task`, `async/await`) over GCD (`DispatchQueue`).

## SwiftLint Rules

Key enforced rules:
- Trailing newlines (single)
- No trailing whitespace
- Max 1 consecutive blank line
- Use trailing closure syntax
- Use implicit return in single-expression closures
- Use `.isEmpty` not `.count == 0`
- Use `.first`/`.last` not subscript access

Disabled rules (allowed):
- `line_length`, `identifier_name`, `type_name`, `force_unwrapping`

Run `swiftlint --fix` to auto-correct.
