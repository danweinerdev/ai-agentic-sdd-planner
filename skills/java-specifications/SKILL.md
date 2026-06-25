---
name: java-specifications
description: "Structural verification for Java and Kotlin — SpotBugs/Error Prone, Detekt. Load when planning, implementing, or reviewing Java/Kotlin code (.java, .kt; build.gradle, pom.xml)."
disable-model-invocation: true
---

# Java / Kotlin — Structural Verification

## Tools

| Tool | When | What it catches |
|------|------|-----------------|
| SpotBugs / Error Prone | If configured in project | Null dereference, concurrency bugs, resource leaks |
| Detekt (Kotlin) | Kotlin projects, if configured | Code smells, complexity, potential bugs |

## Minimum Bar

Run the project's existing static analysis if configured (check Gradle/Maven plugins). Don't introduce new tools unless the project already uses them.
