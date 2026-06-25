---
name: typescript-specifications
description: "Structural verification for TypeScript and JavaScript — tsc --noEmit, linter (eslint/biome). Load when planning, implementing, or reviewing TypeScript/JavaScript code (.ts, .tsx, .js, .jsx; tsconfig.json, package.json)."
disable-model-invocation: true
---

# TypeScript / JavaScript — Structural Verification

## Tools

| Tool | When | What it catches |
|------|------|-----------------|
| `tsc --noEmit` | TypeScript projects | Type errors, missing properties, incorrect generics |
| Linter (eslint / biome) | If configured in project | Unused variables, unreachable code, common bugs |

## Minimum Bar

Type-check TypeScript projects. Run the linter if configured.
