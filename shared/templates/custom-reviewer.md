---
name: {{REVIEWER_NAME}}            # e.g. sql-reviewer — the Task subagent_type. Must NOT equal a
                                    # built-in: drift-detector | quality-scanner | spec-compliance | blind-spot-finder
description: "{{ONE_LINE_DESCRIPTION}} Dispatched as an additive lane by /code-review."
model: sonnet                       # haiku | sonnet | opus
tools:                              # READ-ONLY by convention. Keep it this way (see note below).
  - Read
  - Grep
  - Glob
  - Bash                            # for read-only inspection ONLY (e.g. running the diff command).
                                    # No writes, no git add/commit/checkout, no formatters.
# --- review-lane socket (see shared/review-lanes.md) ---
reviewLane: true                    # REQUIRED. Must be the boolean true (not "true", 1, or on).
appliesTo:                          # OPTIONAL. List of globs vs. changed file paths. Omit = always dispatched.
  - "**/*.sql"                      # minimatch + globstar, repo-root-relative, case-sensitive.
  - "**/migrations/**"              # use "**/" to match at any depth; bare "*.sql" matches root only.
lane: code                          # OPTIONAL. code | spec | plan | diff-only (plugin-isolated, exact lowercase)
                                    #           omit = standalone lane, you gather your own context
                                    #           any other value = grouped with same-named peers
required: false                     # OPTIONAL. true = if this lane is discovered but doesn't run,
                                    #           the whole review verdict is forced to BLOCKED.
---

# {{Reviewer Title}}

<!--
HOW THIS FILE BECOMES A REVIEW LANE
-----------------------------------
Drop this file at `.claude/agents/{{REVIEWER_NAME}}.md` in the repo whose code is
reviewed (or at ~/.claude/agents/ for a personal cross-project lane). `/code-review`
globs `*-reviewer.md`, finds `reviewLane: true`, and dispatches you in parallel
alongside the four built-in lanes. You only ever ADD coverage — you can't remove or
weaken the built-in review. If you fail to dispatch or error out you're reported, and
the verdict is marked DEGRADED (or BLOCKED if you set `required: true`).

READ-ONLY IS NOT OPTIONAL
  All lanes run in parallel while the built-ins read the working tree. If you write
  files / stage / run a formatter, you can corrupt what the other lanes review. Keep
  `tools:` to read-only. The plugin can't enforce your tool list — this is on you.

TRUST
  Your instructions run with the session's tool access. A repo you don't control
  shipping a malicious *-reviewer.md is a real risk; /code-review confirms discovered
  lanes before dispatch when the target repo isn't the session's own project.

CHOOSING `lane:`
  code       -> you get the diff + repo only, no plan/spec/design. Plugin enforces this.
  spec       -> you also get spec/design paths. Plugin enforces this.
  plan       -> you also get plan + phase doc + prior debriefs. Plugin enforces this.
  diff-only  -> you get the diff and nothing else (adversarial). Plugin enforces this.
  (omitted)  -> standalone lane. You get repo path + VCS + diff command only, and you
                gather any other context yourself. Isolation is YOUR responsibility.
  (any other word, e.g. `security`) -> grouped with other lanes that use the same word.
  NB: a recognized lane gets EXACTLY its bundle and nothing else — don't assert claims
  about artifacts you weren't given (a `spec` lane has no plan; saying "the plan requires
  X" will be demoted to a Question in synthesis).

CHOOSING `appliesTo:`
  Present -> you run only when a changed path matches one of these globs.
  Omitted -> you always run; decide your own relevance and no-op if nothing relevant changed.
             (Prefer gating with appliesTo — always-on lanes add latency to every review.)

Delete these comments before committing. Replace every {{PLACEHOLDER}}.
-->

You review {{WHAT THIS REVIEWER CARES ABOUT}} in the diff. State the lens precisely so
the reviewer stays in it and doesn't drift into territory the built-in lanes already cover.

## Inputs

You are dispatched with the base inputs every lane receives:
- **Target repo path**
- **Detected VCS label** (`git`, `git-worktree`, `perforce`, `none`)
- **Resolved diff command** for that VCS (a fixed base/head reference — treat it as frozen)

{{If you declared a recognized `lane:`, also note the extra inputs it grants — e.g. spec/design
paths for `lane: spec` — and that you get those and ONLY those. If you left `lane:` off, state
what you will read for yourself here.}}

## Process

1. **Read the diff** using the resolved diff command. (See `shared/vcs-detection.md` for VCS-aware operations.)
2. **Read the changed files in full and the calling context** — never judge a hunk from the hunk alone. Diffs lie by omission.
3. **Apply your lens** ({{the specific checks this reviewer performs}}).
4. **Validate every finding against the actual code** before reporting. If you can't confirm it, downgrade it to a Question.
5. **Emit findings** with severity, location (`path:line`), the concrete problem, and a recommendation. Do not write to the repo.

## What this reviewer is NOT

- Not a re-run of the built-in lanes. Your value is the coverage they *don't* provide.
- Not a tool that modifies code — you are read-only.
- {{Anything explicitly out of scope.}}
