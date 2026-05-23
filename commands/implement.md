---
name: implement
description: "Execute a plan phase — implement tasks, track progress, update statuses. Triggers: /implement, implement this, start phase, execute plan, build this"
---

# /implement — Execute Plan Phase

## Path Resolution
**Artifacts** (Plans/, Research/, Specs/, etc.) are read from and written to the **planning root**.
Read `planning-config.json` (at repo root) to find the planning root:
- `planningRoot` of `"."` or absent → artifacts at repository root
- `planningRoot` of `"<dir>"` → artifacts under `<dir>/` from repo root
- `planningRoot` of `"/absolute/path"` → artifacts in an external directory

**Templates and schema** (`shared/`) are read from the **plugin directory**, not from the planning root. The plugin directory contains `commands/`, `agents/`, and `shared/` as siblings — find it by globbing for `**/commands/research.md` in both the current directory and `~/.claude/plugins/cache/`. If multiple matches are found (e.g., multiple cached plugin versions), sort by version number and use the highest. Then go one level up.

## When to Use
When a plan is approved and you're ready to implement a phase. This skill **coordinates** implementation: it delegates actual code work to `code-implementer` agents, runs them in parallel where dependencies allow, triggers `quality-scanner` agents after each task for a fast intent-blind quality check, and manages the review-fix cycle. It bridges the gap between `/plan` (which defines *what* to build) and `/debrief` (which captures *what happened*).

Per-task reviews during `/implement` dispatch `quality-scanner` directly (not the full four-lane review) because the relevant question after a single task is "is this code any good?" not "does the whole phase still align with the plan?". The full four-lane orchestrated review happens at end-of-phase via `/code-review`, which dispatches `drift-detector`, `quality-scanner`, `spec-compliance`, and `blind-spot-finder` in parallel and synthesizes their reports.

## Process

### 1. Select Phase
- Scan `Plans/` for plans whose README frontmatter `status` is `approved` or `active` (skip `draft`, `complete`, and `archived`)
- Ask which plan and phase to implement (or infer from context)
- Read the plan README to understand overall context and phase dependencies
- Read the target phase document to get the task list
- Verify prerequisites:
  - Plan status must be `approved` or `active`
  - Phase status must be `planned` or `in-progress` (not `complete`, `blocked`, or `deferred`)
  - Any phases in `depends_on` must be `complete`
- If plan status is `approved`, update the README frontmatter `status` to `active`
- If phase status is `planned`, update it to `in-progress`

### 2. Locate Target Codebase
- Read `planning-config.json` for the repository mapping
- If `planMapping` has an entry for this plan, find the target repo
- If `planning-config.local.json` exists, read it for local filesystem paths
- Verify the target repo/directory exists and is accessible

### 3. Load Context
- Read related specs from `Specs/` (referenced in plan README `related` field)
- Read related designs from `Designs/`
- Review any previous phase debriefs in `Plans/<PlanName>/notes/` for context from prior phases
- Build a mental model of what this phase needs to deliver

### 4. Verify Task Readiness

Before executing any tasks, audit every task in the phase for a `verification` field in its frontmatter entry. Every task must answer the question: **"How do we know this work is good and complete?"**

Also read `shared/language-verification.md` and detect the target project language. Verify that the phase includes the language-appropriate structural checks (sanitizers, static analysis, type checking) — either in individual task verification fields or as a dedicated verification task. If missing, flag this alongside any tasks missing verification criteria.

Scan the phase's `tasks[]` array and separate tasks into two lists:
- **Ready**: tasks that have a non-empty `verification` field with specific, observable criteria
- **Missing verification**: tasks where `verification` is absent, empty, or vague (e.g., "works correctly", "done", "it works")

#### Forward-reference audit

For every task that DOES have verification, also scan its verification text for **forward references** — backtick-quoted identifiers (types, functions, concepts) that don't exist yet in the target codebase and aren't defined in earlier phases of this plan.

A forward reference looks like a verification clause that names a symbol introduced by a later phase. Example: a Phase 2 task whose verification says "tests cover: pre-existing **OnDemand** started service is rolled back" — when `OnDemand` is introduced in Phase 3. The task can't be fully verified at Phase 2 implementation time without a test-only seam or a deferred test.

The check:

1. **Extract candidate identifiers** from each verification field — backtick-quoted symbols (e.g., `OnDemand`, `start_service`, `DependencyState`), and capitalized type-like names if they're not already standard library types.
2. **For each candidate, check three places:**
   - The target codebase: use `Grep` for the literal symbol (rough — you're looking for "does this exist anywhere yet?"). If found, it's not a forward reference.
   - Earlier phase docs in this plan (`<NN>-*.md` files with phase number ≤ current). If a phase ≤ N defines it, it's not a forward reference.
   - This phase's own frontmatter or body. If this phase introduces it, it's not a forward reference.
3. **If a candidate is found ONLY in a later phase doc** (`<NN>-*.md` with phase number > current), or NOT found anywhere in the plan or codebase, treat it as a forward reference.

This is a heuristic, not a parser. Capitalized words like `Result`, `String`, `Vec`, `HashMap`, `Option` (and language-standard equivalents) are not forward references — skip them. When ambiguous, lean toward flagging — false positives the user can dismiss in 5 seconds; false negatives create implementation-time test seams.

**If all tasks are ready and no forward references are found** — proceed to step 5.

**If any tasks are missing verification OR have forward references** — present the combined list to the user:

```
## Verification Issues

### Missing verification (no defined criteria)

- **1.2: Add user authentication** — no `verification` field
- **1.4: Set up logging** — no `verification` field

Each task needs a specific answer to "how do we know this is done?"
Examples: "login returns a JWT and refresh flow works", "logs appear
in CloudWatch within 5s of a request"

### Forward references (verification names symbols defined in later phases)

- **2.3: Registry-wide rollback** — verification mentions `OnDemand`, defined in phase 3
- **2.3: Registry-wide rollback** — verification mentions `start_service`, defined in phase 3

Forward references force implementation-time compromises (test-only
seams, deferred tests). Either reword the verification to be self-
contained at this phase, or document the seam explicitly in the phase
doc with a marker like "(Phase N+1: <symbol> not yet introduced)".
```

Then ask the user to choose:
1. **Fix now** — pause and update verification fields (add criteria for missing; reword or annotate forward references) before continuing
2. **Proceed anyway** — acknowledge the issues and implement; for forward references, the implementer may need to insert test-only seams documented in the phase doc
3. **Abort** — stop implementation to fix the plan first

If the user chooses option 1, update each task's `verification` field, then proceed. If the user chooses option 2, proceed but include a warning in the wave summary for each affected task — and where forward references force a test-only seam, the implementer's report and the eventual debrief should call that seam out explicitly. If the user chooses option 3, stop.

### 5. Build Dependency Graph & Execute in Waves

Analyze the phase's task list and `depends_on` fields to identify **waves** — groups of tasks that can run concurrently:

```
Wave 1: Tasks with no dependencies (e.g., 1.1, 1.2, 1.3)
Wave 2: Tasks depending only on Wave 1 tasks (e.g., 1.4 depends on 1.1)
Wave 3: Tasks depending on Wave 2 tasks
...
```

#### Advisory Overlap Analysis

Before launching each wave, check whether two or more tasks in the same wave might touch the same files (based on their subtask descriptions and the target codebase structure). If overlap is likely, warn the user and offer to serialize those tasks instead of running them in parallel.

#### For Each Wave

**a. Launch implementer agents (parallel)**
- For each task in the wave, launch a `sdd-planner:code-implementer` agent via the Task tool (use the plugin-namespaced name — bare `code-implementer` will not resolve)
- Each agent receives: task ID, title, subtasks, relevant spec/design context, target codebase path, any notes from prior task debriefs
- Launch all tasks in the wave as concurrent Task tool calls
- Update each task's status to `in-progress` in the phase frontmatter

**b. Collect results**
- As each agent completes, collect: files changed, test results, commit hash, issues
- If an agent reports failure/blockers → mark task `blocked`, record the reason
- If an agent reports success → proceed to review

**c. Review completed tasks**
- For each successfully completed task, dispatch `sdd-planner:quality-scanner` via the Task tool (use the plugin-namespaced name — bare `quality-scanner` will not resolve)
- Render the dispatch prompt from `shared/templates/quality-scan-prompt.md`. The template handles the boilerplate framing (intent-blind framing, scope, output table); your job per-dispatch is to fill in `FOCUS_LIST` — a 4–8 item curated list of risk areas in this specific diff. That is where the orchestrator's judgment lives.
- Scope the review to that task's changes — pass the target repo path, the file list, and the commit range from the implementer's report via the template's placeholders
- The scanner evaluates the code intent-blind: correctness, safety, maintainability, testing, over-engineering — including **comment quality** (flags WHAT-restating comments, PR-time context references, tombstones for deleted code, and any comment that doesn't earn its place by capturing non-obvious WHY)
- Do **not** pass plan/spec/design context — `quality-scanner` is deliberately intent-blind, and the full orchestrated `/code-review` at end-of-phase covers the plan/spec/design perspective

**d. Process review findings**
- **Critical findings** → resume the `sdd-planner:code-implementer` agent to address the issue, then re-review
- **Non-critical findings** (Major/Minor/Question) → collect and present to user after the wave completes
- Maximum 2 review-fix cycles per task. If critical issues remain after 2 cycles, mark the task as `needs-attention` and move on.

Never use "pre-existing" to justify deferring or hiding a finding. "Pre-existing" describes origin, not impact. Present findings by what they do to the user, not when they were introduced. The user decides what is worth fixing.

Never downscope a finding, recommendation, or fix by estimating how long it would take a human. Agents are not constrained by human development timelines. The right fix is right; surface it. Prefer a smaller change only when it is genuinely better on its own merits — clearer, lower risk, smaller surface area — never because a larger one would "take too long." The user decides what is worth fixing; don't pre-decide for them on time grounds.

**e. Finalize wave**
- Update completed task statuses to `complete`
- Check off subtask checklists (`- [x]`) in the phase doc
- Update the `updated` date in the phase frontmatter
- Present non-critical findings summary to user using the `shared/templates/per-task-findings.md` template — render once per task with the scanner's table and your recommendation. Keeping the structure consistent across tasks lets the user compare findings at a glance.
- Ask user for decisions on any findings requiring human judgment
- Proceed to next wave

### 6. Phase Completion
Once all tasks are complete (or all remaining tasks are blocked):

**All tasks complete:**
- Update phase status to `complete` in both the phase doc and plan README
- Update `updated` dates
- If all phases in the plan are now complete, set the plan README frontmatter `status` to `complete`
- Suggest running `/debrief` to capture what happened

**Some tasks blocked:**
- Keep phase status as `in-progress`
- Present the blocked tasks and their blockers to the user
- Ask how to proceed:
  - Resolve blockers and continue
  - Defer blocked tasks and mark phase as `complete`
  - Mark phase as `blocked`

## Task Execution Details

### Working with Subtasks
Phase docs contain subtask checklists under each task heading:
```markdown
## 1.1: Task Title

### Subtasks
- [ ] Implement the data model
- [ ] Add validation logic
- [ ] Write unit tests
```

As agents complete each subtask, the coordinator checks them off:
```markdown
- [x] Implement the data model
```

This gives real-time progress visibility in the plan artifacts.

### Handling Dependencies
Tasks may have `depends_on` in their frontmatter. The coordinator builds waves from these:
1. Wave 1: Tasks with no dependencies
2. Wave 2: Tasks whose dependencies are all in Wave 1 (and will be complete)
3. Wave 3: Tasks whose dependencies are all in Waves 1-2
4. Skip tasks whose dependencies are `blocked` or `deferred`

### Resuming Interrupted Work
If a phase is already `in-progress` (from a previous session):
- Read the current state of all tasks
- Skip `complete` tasks
- Resume `in-progress` tasks (re-launch their agents)
- Continue with `planned` tasks in dependency order

## Escalation Rules

These conditions require stopping and asking the user:

1. **Blocked task**: An agent can't complete a task after 2 attempts. Present the issue and ask for guidance.
2. **Spec ambiguity**: The spec or design doesn't cover a case encountered during implementation. Ask the user to clarify rather than guessing.
3. **Scope expansion**: Implementation reveals work not captured in the plan. Flag it — don't silently expand scope.
4. **Destructive action**: Any action that would delete data, modify production config, or affect shared systems needs explicit approval.
5. **Unresolvable review findings**: `quality-scanner` flags critical issues that the implementer can't resolve after 2 review-fix cycles. Escalate to user.
6. **File conflicts**: If parallel tasks in a wave produce conflicting changes to the same files, present the conflict to the user before proceeding.

Everything else is autonomous. Don't ask for confirmation between waves.

## Output
Updates existing plan artifacts in place:
- Phase doc: task statuses, subtask checklists, `updated` date
- Plan README: phase status, `updated` date

Code changes go to the target repository (not the planning root).

## Context
- Orchestration: `shared/orchestration.md`
- Schema: `shared/frontmatter-schema.md`
- Per-task findings template: `shared/templates/per-task-findings.md`
- Quality-scanner dispatch template: `shared/templates/quality-scan-prompt.md`
- Target plan: `Plans/<PlanName>/` (status: `approved` or `active`)
- Related specs: `Specs/`
- Related designs: `Designs/`
- Prior debriefs: `Plans/<PlanName>/notes/`
- Local repo paths: `planning-config.local.json`
