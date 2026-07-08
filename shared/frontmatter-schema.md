# Frontmatter Schema

Single source of truth for all artifact metadata in this project.

## Common Fields

Every artifact includes these fields (one exception: `phase` docs omit `tags` and `related` — they inherit the plan's):

```yaml
title: "Human-readable title"
type: research | brainstorm | spec | design | plan | phase | debrief | retro | diagram
status: <type-specific, see below>
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [tag1, tag2]
related: [Specs/FeatureName, Research/topic-slug.md]
```

`related` entries are planning-root-relative: use the **directory** path for specs, designs, and plans (`Specs/FeatureName`, `Designs/ComponentName`, `Plans/PlanName`), and the **file** path for flat artifacts (`Research/topic-slug.md`, `Brainstorm/topic-slug.md`, `Retro/YYYY-MM-DD-slug.md`, `Diagrams/slug.md`). Consumers that need the document behind a directory entry append `/README.md`.

## Status Values by Type

| Type | Statuses |
|------|----------|
| research | `draft`, `active`, `archived` |
| brainstorm | `draft`, `active`, `archived` |
| spec | `draft`, `review`, `approved`, `implemented`, `superseded` |
| design | `draft`, `review`, `approved`, `implemented`, `superseded` |
| plan | `draft`, `approved`, `active`, `complete`, `archived` |
| phase | `planned`, `in-progress`, `complete`, `blocked`, `deferred` |
| task | `planned`, `in-progress`, `complete`, `blocked`, `deferred` |
| debrief | `draft`, `complete` |
| retro | `draft`, `complete` |
| diagram | `draft`, `active`, `archived` |

## Plan Schema

### Plan README.md

```yaml
---
title: "Plan Title"
type: plan
status: active
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [tag1, tag2]
related: [Specs/FeatureName, Designs/ComponentName]
phases:
  - id: 1
    title: "Phase Title"
    status: planned
    doc: "01-Phase-Title.md"
  - id: 2
    title: "Phase Title"
    status: planned
    doc: "02-Phase-Title.md"
    depends_on: [1]
---
```

Body contains: Overview, Architecture, Key Decisions, Dependencies.
No status tables in the body — the dashboard reads phases from frontmatter.

### Phase Doc (01-Phase-Title.md)

```yaml
---
title: "Phase Title"
type: phase
plan: PlanName
phase: 1
status: in-progress
created: YYYY-MM-DD
updated: YYYY-MM-DD
deliverable: "What this phase delivers"
tasks:
  - id: "1.1"
    title: "Task title"
    status: planned
    verification: "How we know this task is good and complete"
  - id: "1.2"
    title: "Task title"
    status: planned
    depends_on: ["1.1"]
    verification: "Specific criteria to confirm correctness"
---
```

#### Task Fields

| Field | Required | Description |
|-------|----------|-------------|
| `id` | yes | Task identifier (e.g., "1.1") |
| `title` | yes | Human-readable task title |
| `status` | yes | Task status (see status values above) |
| `depends_on` | no | List of task IDs this task depends on |
| `verification` | yes | How we know the work is good and complete — name each new or changed behavior to cover, not test counts. Where the check is commandable, include the exact command and expected observable output (e.g., `cargo test auth:: — 14 pass incl. the new refresh-expiry case`); prose-only criteria are for behavior no command can observe |

Body contains task detail sections keyed by task ID as headings:

```markdown
## 1.1: Task Title

### Subtasks
- [ ] Subtask one
- [ ] Subtask two

### Notes
Implementation notes...
```

## Debrief Schema

Debriefs live at `Plans/<PlanName>/notes/<NN>-Phase-Name.md` and add three fields to the common set:

```yaml
---
title: "Phase N Debrief: Phase Title"
type: debrief
status: complete        # draft while being written incrementally
plan: PlanName          # the plan directory name
phase: 1                # the phase number this debrief covers
phase_title: "Phase Title"
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: []
related: []
---
```

## Dashboard Color Mapping

Consumed by the companion `sdd-dashboard` plugin and by `/diagram`'s status styling (`classDef` colors):

- `complete` / `approved` / `implemented` -> green
- `in-progress` / `active` / `review` -> amber
- `planned` / `draft` -> gray
- `blocked` -> red
- `deferred` / `archived` / `superseded` -> muted
