Review commit `{{COMMIT_HASH}}` in `{{REPO_PATH}}` (branch `{{BRANCH}}`). Single commit labeled `{{COMMIT_MESSAGE}}`.

Run **intent-blind**. Do not read any plan, spec, design, research, or debrief artifact. Evaluate strictly on code quality.

## Scope
- Just commit `{{COMMIT_HASH}}`. Use `git show {{COMMIT_HASH}} --stat` and `git show {{COMMIT_HASH}} -- <file>` per file.
- Files touched:
{{FILES_LIST}}

## What the commit does (per its own message)
{{CLAIMED_CHANGES}}

## Specific things to verify
{{FOCUS_LIST}}

## Output
Use this exact table shape:

| # | Severity | Lens | Location (file:line) | Finding |

Severities: **Critical** (must-fix before this task is accepted), **Major**, **Minor**, **Question**.

Lenses: **Correctness**, **Safety**, **Maintainability**, **Testing**, **Over-Engineering**.

After the table, give a one-paragraph **Recommendation** (block / fix-then-accept / accept-with-followups / accept).

Validate every finding against the actual diff and the surrounding file context, not just the diff hunk. Diffs lie by omission — read the full file when a hunk's context isn't sufficient.

Do not include any plan-aware reasoning. Do not say "this matches the spec" or "this satisfies the verification" — you don't have the spec.

<!--
Placeholder reference:

- COMMIT_HASH        — short SHA of the commit under review
- REPO_PATH          — absolute path to the target repo on disk
- BRANCH             — branch the commit lives on (typically the
                       branch the implementer pushed to)
- COMMIT_MESSAGE     — the commit's own subject line, including the
                       task id suffix if present (e.g.,
                       "ark-core: DependencyState (2.1)")
- FILES_LIST         — bullet list of file paths touched by the
                       commit. One bullet per file. The scanner uses
                       this to scope its read budget.
- CLAIMED_CHANGES    — the implementer's report of what changed,
                       paraphrased into 2–6 sentences. The scanner
                       reads this to know what to verify but stays
                       intent-blind on plan/spec context.
- FOCUS_LIST         — the orchestrator's curated list of risk areas
                       in this specific diff, rendered as numbered or
                       bulleted concerns. This is the only part of
                       the dispatch that materially varies run-to-run
                       — write it carefully. Examples:
                         1. Does the new validate_x function handle
                            null inputs?
                         2. The implementer claims they renamed all
                            call sites of foo(); spot-check several.
                         3. The new test asserts X but the production
                            change implies Y — read both and confirm
                            consistency.
                       Aim for 4–8 concrete, testable concerns. Avoid
                       vague prompts like "review for correctness".

Rendering rules:
- Send the rendered prompt directly to sdd-planner:quality-scanner via
  the Task tool. The agent's body has its own rules for output format
  and validation discipline; the template provides the framing.
- Do NOT include plan/spec/design/research/debrief content in
  CLAIMED_CHANGES or FOCUS_LIST. Reference symbol names, file paths,
  and concrete behaviors only.
- The "Output" block is normative — do not modify the table headers
  or severity/lens vocabulary. The per-task-findings.md template
  expects this exact shape.
-->
