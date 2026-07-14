---
name: tend
description: "Artifact hygiene — verify statuses, unify tags, check conventions, clean up stale artifacts. Triggers: /tend, tend, check health, what's stale, artifact hygiene, tag audit, organize"
---

# /tend — Artifact Hygiene

## Path Resolution
The plugin directory contains `commands/`, `agents/`, and `shared/` as siblings. Find it by globbing for `**/commands/research/SKILL.md` in both the current directory and `~/.claude/plugins/cache/`; if multiple versions match, sort them as **semantic versions** (like `sort -V`) and use the highest, then strip `commands/research/SKILL.md` from the match. Resolve the planning root (artifacts) and target repository per `shared/path-resolution.md` in the plugin directory.

## When to Use
- Artifacts have accumulated and status is unclear
- Before starting new work, to understand what's active
- Periodically, to keep planning artifacts healthy
- After completing a feature cycle (good time to archive)
- When the plan artifacts feel out of sync with reality

## Pre-flight: Legacy Layout Detection

Before running any mode, check whether `Plans/` uses the **legacy status-subfolder layout** (`Plans/New/`, `Plans/Ready/`, `Plans/Active/`, `Plans/Complete/`) instead of the current **flat layout** (plan directories directly under `Plans/`, with lifecycle tracked in each plan README's frontmatter `status` field).

**Detection**: List the contents of `Plans/`. If any of `New/`, `Ready/`, `Active/`, or `Complete/` exist as subdirectories, the layout is legacy.

If legacy layout is detected:

1. **Report** the finding and show which plans were detected:
   ```
   Legacy Plans/ layout detected — plans are stored in status subfolders.

   Found N plans to migrate:
     - Plans/Active/PlanName/ → Plans/PlanName/ (frontmatter status: active)
     - Plans/Complete/OtherPlan/ → Plans/OtherPlan/ (frontmatter status: complete)
     - Plans/New/NewPlan/ → Plans/NewPlan/ (frontmatter status: draft)
   ```

2. **Warn** the user:
   ```
   This migration will move plan directories up to a flat layout under Plans/
   and ensure each plan's README frontmatter `status` reflects its old folder.
   It will cause a significant number of file moves in version control.
   ```

3. **Wait for confirmation**. If the user declines, skip the migration and continue to the requested mode(s) normally — but flag that subsequent commands assume the flat layout.

4. **If confirmed**, perform the migration:
   - For each plan directory inside a status subfolder:
     - Map subfolder back to a status value: `New/` → `draft`, `Ready/` → `approved`, `Active/` → `active`, `Complete/` → `complete`
     - Read the plan's `README.md` frontmatter `status` field. If absent or inconsistent with the subfolder, set it to the subfolder-derived value (subfolder is the source of truth, since that's how the old workflow tracked it).
     - Use the VCS-appropriate move command from `shared/vcs-detection.md` to move the plan directory from `Plans/<Subfolder>/<PlanName>/` to `Plans/<PlanName>/`
   - Remove the now-empty `New/`, `Ready/`, `Active/`, and `Complete/` subdirectories
   - After all moves, report the results

If `Plans/` already has plan directories directly under it and no status subfolders exist, skip this check entirely — the layout is already flat.

## Modes

| Mode | Purpose | Produces |
|------|---------|----------|
| `migrate` | Pre-flight legacy-layout migration (see above); also runs automatically before other modes when a legacy layout is detected | Layout: plans flat under `Plans/`, status in frontmatter |
| `status` | Verify and update document status fields | Accuracy: documents reflect reality |
| `decisions` | Audit the decision ledger — collisions, stale supersessions, unrecorded decisions | Truth: the ledger is consistent and complete |
| `tags` | Unify tag variants, find connections, identify clusters | Semantics: tags are consistent and meaningful |
| `filenames` | Check naming conventions, suggest renames | Findability: names match content |
| `completeness` | Check for missing frontmatter fields, empty sections | Quality: artifacts are well-formed |

**Dependency chain**: status → decisions → tags → filenames → completeness

Each mode builds on prior work. Status must be accurate before tag analysis is meaningful.

## Invocation

```
/tend                    # Run all modes sequentially (pause between each)
/tend migrate            # Run only legacy layout migration check
/tend status             # Run only status mode
/tend decisions          # Run only decision-ledger audit
/tend tags               # Run only tags mode
/tend filenames          # Run only filenames mode
/tend completeness       # Run only completeness mode
```

## Common Pattern

All modes follow delegate-scan → review-findings → confirm → apply:

1. **Scan**: Invoke the `sdd-planner:researcher` agent to scan artifacts and gather findings (no changes made)
2. **Report**: Primary context presents the agent's findings in categorized format
3. **Confirm**: Wait for user decisions on proposed changes
4. **Apply**: Make confirmed changes and report final state

Never skip confirmation for changes to existing content.

## Mode Details

### Status Mode
Invoke the `sdd-planner:researcher` agent to scan all plans under `Plans/` and compare status fields against reality. The agent returns a list of findings — what is stale, what is inconsistent, and what should be updated. Checks to perform:
- Plans with all phases complete but plan status is still `active` → suggest `complete`
- Plans with status `active` but no phase has started → suggest reverting to `approved`
- Phases where all tasks are complete but phase status is `in-progress` → suggest `complete`
- Specs/designs marked `approved` but their plan is `complete` → suggest `implemented`
- Research/brainstorm still `active` but frontmatter `updated` more than 30 days before today → flag as potentially stale
- Phase status `in-progress` but no task has started → flag inconsistency

**Refresh triggers**: Artifacts may declare an optional `refresh_when` frontmatter field — a list of event-shaped trigger descriptions (e.g., "dependency X ships v3", "Specs/Payments changes", "the vendor answers the webhooks question"). For artifacts that declare it: report each artifact with its triggers and ask the user which (if any) have fired — fired triggers make the artifact stale regardless of its `updated` date, and an artifact whose triggers have all demonstrably not fired is NOT stale even past 30 days. Artifacts without `refresh_when` keep the 30-day rule above. Where a trigger names another artifact (e.g., "Specs/Payments changes"), check that artifact's `updated` date yourself instead of asking.

### Decisions Mode
Resolve the ledger per `shared/decision-log.md` § Ledger location (`Decisions/decisions.md` under the planning root, or each mapped repo's `DECISIONS.md` for external planning roots — audit every resolvable ledger). Skip silently if none exists. Otherwise invoke the `sdd-planner:researcher` agent to audit the decision ledger against `shared/decision-log.md` and the other artifacts. Checks to perform:
- **Collisions among `accepted` entries** — run the structural checks from `shared/decision-log.md` across all accepted pairs, using its scope-overlap definition (shared/nested paths, or artifacts connected via `related` frontmatter; empty scope is global and overlaps everything); the append-time check can miss pairs that predate it. Each collision goes to the user to reconcile — never auto-resolve.
- **Superseded-but-still-cited** — grep `Specs/`, `Designs/`, `Plans/` for `D-NNNN` id citations of entries whose status is `superseded` or `rejected`; flag the citing artifacts as possibly stale. Also flag governed sections that cite no id at all where a scoped accepted entry exists (missing bidirectional link).
- **Fired assumption triggers** — for `assumption`-kind entries carrying `refresh_when`, ask the user which triggers have fired (checking artifact-referencing triggers yourself, as in Status mode); a fired trigger invalidates the assumption — reconcile it like a collision (supersede or reject, then cascade).
- **Duplicate ids** — from concurrent sessions or branch merges: keep the earlier entry's id, renumber the later entry to the next free id, and chase every incoming `supersedes`/`superseded_by` link and artifact citation of the renumbered id. Never resolve by deleting either entry.
- **Broken structure** — supersession links that aren't bidirectional, `scope` paths pointing at artifacts that no longer exist, missing required fields.
- **Unrecorded decisions** — Key Decisions / Design Decisions / Decisions Made sections in approved-or-later artifacts with no corresponding ledger entry; offer backfill (as `proposed` unless the user confirms each).
- **Stale `proposed` entries** — older than 30 days: ask the user to accept, reject, or drop each. Accepting re-runs the full collision check first (append-equivalent event).
- **Rotation** — past ~100 entries, offer to move `superseded` and `rejected` entries to `Decisions/archive-<YYYY>.md` (type `decision-log`, status `archived`); ids stay unique across live ledger and archives, and `accepted`/`proposed` entries never rotate.

### Tags Mode
Invoke the `sdd-planner:researcher` agent to scan all artifact frontmatter for tags and analyze for variants, orphans, missing tags, and clusters. The agent returns the analysis. Checks to perform:
- **Variants**: Find tags that are likely the same thing (`api`/`APIs`/`rest-api`)
- **Orphans**: Tags used in only one document (might be too specific)
- **Missing**: Artifacts with empty tags that could be inferred from content
- **Clusters**: Groups of artifacts that share tag patterns (reveals implicit categories)

### Filenames Mode
Invoke the `sdd-planner:researcher` agent to check naming conventions across all artifacts. The agent returns any violations found. Conventions to check (defined in CLAUDE.md):
- Plans: `Plans/<PlanName>/README.md`, phases `01-Phase-Name.md`
- Specs: `Specs/<FeatureName>/README.md`
- Designs: `Designs/<ComponentName>/README.md`
- Research: `Research/<topic-slug>.md` (kebab-case)
- Brainstorm: `Brainstorm/<topic-slug>.md` (kebab-case)
- Retro: `Retro/YYYY-MM-DD-<slug>.md`
- Diagrams: `Diagrams/<slug>.md` (kebab-case, type `diagram`; statuses `draft`/`active`/`archived`)
- Decisions: `Decisions/decisions.md` (single canonical ledger, type `decision-log`)
- Phase numbering: zero-padded, sequential, no gaps

### Completeness Mode
Invoke the `sdd-planner:researcher` agent to check each artifact against `shared/frontmatter-schema.md`. The agent returns missing fields and empty sections. Checks to perform:
- Required frontmatter fields present (title, type, status, created, updated)
- Body has expected sections per template
- Plans have at least one phase defined
- Phases have at least one task defined
- Related links point to artifacts that exist

## Sequential Execution

When running `/tend` without arguments:

1. Run legacy layout detection pre-flight (if applicable)
2. Run status mode to completion
3. Ask: "Status complete. Continue to decisions?"
4. On confirmation, run decisions mode (skipped silently when no ledger exists), then ask: "Decisions complete. Continue to tags?"
5. On confirmation, run tags mode
6. Ask: "Tags complete. Continue to filenames?"
7. On confirmation, run filenames mode
8. Ask: "Filenames complete. Continue to completeness?"
9. On confirmation, run completeness mode
10. Present final summary

User can stop after any mode.

## Output
Modifies artifacts in place based on user-confirmed changes. No new artifacts created.

## Context
- Orchestration: `shared/orchestration.md`
- Schema: `shared/frontmatter-schema.md`
- Conventions: `CLAUDE.md`
- Agent: `sdd-planner:researcher`
