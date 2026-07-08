---
name: simplify
description: "Post-implementation code cleanup and simplification. Triggers: /simplify, simplify, clean up code, reduce complexity, refactor for clarity"
---

# /simplify — Code Simplification

## Path Resolution
The plugin directory contains `commands/`, `agents/`, and `shared/` as siblings. Find it by globbing for `**/commands/research/SKILL.md` in both the current directory and `~/.claude/plugins/cache/`; if multiple versions match, sort them as **semantic versions** (like `sort -V`) and use the highest, then strip `commands/research/SKILL.md` from the match. Resolve the planning root (artifacts) and target repository per `shared/path-resolution.md` in the plugin directory.

## When to Use
After implementation is complete and tests pass. The goal is reducing complexity without changing behavior — making code easier to read, maintain, and extend.

This is distinct from `/implement` (which builds features) and from a regular code review (which catches bugs). Simplification assumes the code works correctly and asks "can this be clearer?"

## Process

1. **Identify Target**
   - Ask what to simplify: specific files, a module, or the output of a recent plan phase
   - If linked to a plan, read the phase doc and debrief to understand what was built
   - If a `planning-config.local.json` exists, read it to find local repo paths

2. **Analyze Complexity**
   Dispatch `sdd-planner:quality-scanner` in `simplify` mode via the Task tool (use the plugin-namespaced name — bare `quality-scanner` will not resolve). Pass `mode: simplify`, the target repo path, and the target file paths. State in the dispatch prompt that there is **no diff and no VCS range** — the scanner reads the target files directly. The scanner is intent-blind by design — do not pass plan, spec, or design context. Expected return shape: findings grouped by file, each with what the issue is, why it matters, the proposed simplification, and a Risk-of-fix line.

   `quality-scanner` already covers the simplification lenses you want here — structural issues, naming, dead code, and over-engineering — under its Maintainability and Over-Engineering lenses. In `simplify` mode it puts extra weight on the Over-Engineering lens.

   Expect the scanner to validate every finding against the full file and the calling context, not just the hunk, so the risk level it reports is grounded in actual usage.

3. **Present Findings**
   Present the `quality-scanner` agent's findings to the user, grouped by file. For each finding:
   - What the issue is
   - Why it matters (readability, maintainability, or correctness risk)
   - What the simplification would look like
   - Risk level (safe refactor vs. behavior-affecting change)

   Never use "pre-existing" to justify deferring or hiding a finding. "Pre-existing" describes origin, not impact. Present findings by what they do to the user, not when they were introduced. The user decides what is worth fixing.

   Never downscope a simplification by estimating how long it would take a human. Agents are not constrained by human development timelines. The right simplification is right; surface it. Prefer a smaller change only when it is genuinely safer or clearer on its own merits — never because a larger one would "take too long." The user decides what to apply; don't pre-decide for them on time grounds.

4. **Apply Changes**
   With user approval, dispatch `sdd-planner:code-implementer` agent(s) via the Task tool (use the plugin-namespaced name) to apply the approved changes:
   - For each file (or group of independent files), launch a `sdd-planner:code-implementer` agent with the approved simplifications and the target file path
   - The agent makes the change, then runs the project's test suite to verify behavior is preserved
   - Include in the `sdd-planner:code-implementer` dispatch prompt: "This is a simplification task: apply the approved simplifications, run the tests, and if the tests still fail after 2 fix attempts, revert your changes (VCS-appropriate restore per `shared/vcs-detection.md`) and report the failure — leave the tree clean."
   - If no test suite exists, flag this as a risk and ask the user to verify manually
   - Changes to independent files can be parallelized across multiple `code-implementer` agents; changes that affect shared interfaces must be serialized

5. **Record**
   If this simplification was part of a plan phase:
   - Note what was simplified in the phase debrief (via `/debrief`)
   - Update the phase's task statuses if simplification was a tracked task

## Escalation Rules

Two conditions require stopping and asking the user:

1. **Test failure after change**: The simplification broke something. The implementer has already reverted and left the tree clean; present the failure and ask whether to retry with a different approach or drop the simplification.
2. **Behavior change detected**: The simplification would change observable behavior (not just internal structure). Present the change and ask whether to proceed.

Everything else is autonomous — don't ask for confirmation between individual file changes.

## Output
Modifies code files in the target repository. No planning artifacts are created unless the user requests a record of changes.

## What This Is NOT
- Not a feature implementation (use `/implement`)
- Not a bug fix (fix bugs directly)
- Not an optimization (this is about clarity, not performance)
- Not a rewrite (preserve existing structure, just clean it up)

## Context
- Orchestration: `shared/orchestration.md`
- Schema: `shared/frontmatter-schema.md`
- Local repo paths: `planning-config.local.json`
- Agents: `sdd-planner:quality-scanner`, `sdd-planner:code-implementer`
