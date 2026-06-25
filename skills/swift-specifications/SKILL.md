---
name: swift-specifications
description: "Structural verification for Swift — SwiftLint, TSAN for concurrency. Load when planning, implementing, or reviewing Swift code (.swift; Package.swift, .xcodeproj)."
disable-model-invocation: true
---

# Swift — Structural Verification

## Tools

| Tool | When | What it catches |
|------|------|-----------------|
| SwiftLint | If configured in project | Style violations, force-unwraps, unused code |
| TSAN (`-sanitize=thread`) | Concurrency, actors, async/await with shared state | Data races |

## Minimum Bar

Run SwiftLint if configured. Consider TSAN for concurrent code.
