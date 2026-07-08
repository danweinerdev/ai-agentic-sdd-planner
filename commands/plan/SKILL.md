---
name: plan
description: "Create or expand a structured implementation plan with phases, tasks, subtasks, and verification criteria. Re-running on an existing plan deepens it — adds tasks, fills gaps, refines subtasks. Do NOT enter plan mode — this skill produces plan artifacts directly. Triggers: /plan, create a plan, plan this, implementation plan, expand plan, add detail, break down, breakdown, expand phase"
---

# /plan — Create or Expand an Implementation Plan

## Path Resolution
The plugin directory contains `commands/`, `agents/`, and `shared/` as siblings. Find it by globbing for `**/commands/research/SKILL.md` in both the current directory and `~/.claude/plugins/cache/`; if multiple versions match, sort them as **semantic versions** (like `sort -V`) and use the highest, then strip `commands/research/SKILL.md` from the match. Resolve the planning root (artifacts) and target repository per `shared/path-resolution.md` in the plugin directory.

## When to Use
- When you need to break down a feature, project, or initiative into an actionable plan with phases, tasks, subtasks, and verification criteria.
- When you want to deepen an existing plan — add tasks, fill in missing verification, expand subtask checklists, or refine acceptance criteria as you learn more.

Both cases run through the same process below. The skill detects whether the named plan already exists and switches into **Revise mode** automatically.

## Process

### 1. Determine Mode (Create vs Revise)

- If the user hasn't already specified it, ask what they want to plan (feature name, scope, goals).
- If `Plans/<PlanName>/README.md` already exists, switch to **Revise mode** — load the README and only the phase docs in scope for this revision into context (delegate a full-plan sweep to the researcher step instead of reading every phase doc yourself) and proceed to step 2.
- Otherwise, you're in **Create mode** — proceed to step 2 with no existing plan to load.

If the existing plan's `status` is `complete` or `archived`, confirm with the user before revising it — those plans are usually frozen.

### 2. Gather Context (delegated to `sdd-planner:researcher`)

Invoke the `sdd-planner:researcher` agent and ask it to return a **structured** summary, not freeform notes:

- **Relevant requirements** — spec items under `Specs/` that this plan should cover
- **Architectural constraints** — design decisions in `Designs/`, component boundaries, interfaces, contracts that constrain implementation
- **Background** — research, brainstorms, retros bearing on this work
- **Related plans** — other plans in `Plans/` that touch the same area (filter by `status` — usually `active`, `approved`, and plans completed within roughly the last three months; tell the researcher explicitly to include the latter, since it skips `complete` plans by default)
- **Existing code** — implementations already present in the target repo that this plan would extend, modify, or replace
- **Current coverage and gaps** — in Revise mode, what the existing tasks and subtasks already address, and what's missing, vague, or contradicted by the latest specs/designs. In Create mode, this comes through as "which spec requirements have no plan covering them yet."

Use this structured summary as the input to step 3 — every drafting decision should trace back to something the researcher surfaced.

### 3. Draft Plan Structure

**Create mode:**
- Determine the plan name (PascalCase, no spaces).
- Break work into phases with clear deliverables — typically 3-7 for a substantial feature. A small feature may legitimately be a single phase; never pad with filler phases.
- Each phase gets 2-6 tasks.
- Identify dependencies between phases.

**Revise mode:**
- Review the existing phase list against the researcher's gap analysis.
- Identify: new tasks to add, existing tasks that need refinement (vague verification, missing subtasks, outdated notes), missing phases.
- **Preserve completed work.** Never delete or rewrite tasks that are already `complete` or referenced in a phase debrief under `notes/`. Refinements to completed tasks should be additive (new acceptance criteria, follow-up tasks) or noted as future work.
- Preserve existing task IDs and ordering. Append new tasks with the next available ID in their phase.

**Both modes:**
- **Every task must have a `verification` field** — a specific answer to "how do we know this work is good and complete?" that names specific behaviors to cover (e.g., "parser handles valid, malformed, and empty input", "endpoint returns 200 with valid payload and 400 with missing fields"). Vague criteria like "works correctly" or test counts are not acceptable — verification means each new or changed behavior has a corresponding check. In Revise mode, audit existing tasks and add `verification` to any that lack it.
- **Include structural verification:** Read `shared/language-verification.md` and detect the target project language. Include the language-appropriate structural checks (sanitizers, static analysis, type checking) in verification fields where relevant — either per-task or as a dedicated verification task in each phase.
- Present the structure (phases, tasks, refinements) to the user for feedback before writing files.

### 4. Write Plan Files

**Create mode:**
- Create `Plans/<PlanName>/README.md` using `shared/templates/plan-readme.md` with `status: draft`.
- Create numbered phase docs using `shared/templates/plan-phase.md`.
- Create `Plans/<PlanName>/notes/` directory for future debriefs. Drop a `.gitkeep` (or VCS-equivalent placeholder) inside so the empty directory survives cloning.
- Populate frontmatter with all phase/task metadata.

**Revise mode:**
- Update the existing README and phase doc frontmatter (`updated` date, new phase/task entries, refined `verification`).
- Create new phase files only when new phases are introduced.
- Leave existing `notes/` debriefs untouched.

**Both modes — body content depth is mandatory:**

For each task, write a `## <ID>: Task Title` section that includes:
- **`### Subtasks`** — a checklist (`- [ ]`) of the concrete implementation steps the implementer will work through. Not "implement X" — the actual steps a person would tick off (e.g., "add migration", "wire the handler", "cover the empty-input case in tests").
- **`### Notes`** — implementation guidance, edge cases, references to specific design sections, gotchas the researcher surfaced. If a task can't be broken into subtasks because it depends on research the implementer will do, say that explicitly here — don't leave the section blank.

Plus:
- Phase-level **Acceptance Criteria** as a checklist.
- Plan README sections: **Overview**, **Architecture** (with Mermaid diagrams where structure helps — prefer `graph TD` / `flowchart LR` over ASCII art), **Key Decisions**, **Dependencies**.

Shallow tasks with no subtasks or notes are not acceptable output — they're the failure mode this skill exists to prevent.

### 5. Review

- Invoke the `sdd-planner:plan-reviewer` agent to review the complete plan.
- Address any issues raised by the reviewer.
- Once review passes:
  - **Create mode:** update the plan README frontmatter `status` to `approved`.
  - **Revise mode:** if `status` is `draft`, set it to `approved` once the review passes (same as Create mode — a re-run on a never-approved plan must not strand it in `draft`); otherwise leave `status` as-is.
- Then re-read the frontmatter and confirm it parses as YAML and includes `title`, `type`, `status`, `created`, `updated`, `tags`, `related`.

## Output
```
Plans/<PlanName>/
├── README.md              # Plan overview with phases in frontmatter
├── 01-Phase-Name.md       # Phase 1 with tasks in frontmatter, subtasks + notes in body
├── 02-Phase-Name.md       # Phase 2
├── ...
└── notes/                 # Empty (Create) or pre-existing debriefs (Revise)
```

Plan lifecycle (`draft` → `approved` → `active` → `complete`) is tracked in the README frontmatter `status` field. The plan directory stays put.

## Document Structure

### README.md
See `shared/frontmatter-schema.md` for the plan frontmatter schema. Body contains:
- **Overview**: What the plan delivers and why
- **Architecture**: High-level technical approach, with Mermaid diagrams
- **Key Decisions**: Major choices and rationale
- **Dependencies**: External prerequisites

### Phase Docs
See `shared/frontmatter-schema.md` for the phase frontmatter schema. Body contains:
- **Overview**: What the phase delivers
- **Task sections**: Each headed by task ID (e.g., `## 1.1: Task Title`) with:
  - `### Subtasks` — checklist of concrete implementation steps
  - `### Notes` — implementation guidance, edge cases, design references
- **Acceptance Criteria**: Phase-level completion criteria as a checklist

## Context
- Orchestration: `shared/orchestration.md`
- Templates: `shared/templates/plan-readme.md`, `shared/templates/plan-phase.md`
- Schema: `shared/frontmatter-schema.md`
- Existing plans: `Plans/` (status in each plan's `README.md` frontmatter)
- Related specs: `Specs/`
- Related designs: `Designs/`
- Agents: `sdd-planner:researcher`, `sdd-planner:plan-reviewer`
