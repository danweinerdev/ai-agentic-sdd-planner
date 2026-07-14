---
title: "Decision Ledger"
type: decision-log
status: active
created: 2026-07-13
updated: 2026-07-13
tags: [decisions]
related: [Research/decision-log.md]
decisions:
  - id: D-0001
    kind: decision
    status: superseded
    superseded_by: D-0004
    date: 2026-07-13
    decided_by: user
    statement: "User decisions are tracked as durable truth in a single canonical ledger, Decisions/decisions.md, with a machine-readable decisions[] frontmatter array."
    rejected: [one-MADR-file-per-decision as the primary store, per-plan ledgers, MCP-server-backed store]
    rationale: "One file to read/grep suits LLM consumption; the decisions[] array follows the existing phases[]/tasks[] frontmatter-as-machine-layer convention; decisions like concept definitions cross plans, so the ledger is global with per-entry scope[] filtering."
    scope: []
    tags: [decision-log, architecture]
    reversibility: two-way
  - id: D-0002
    kind: decision
    status: accepted
    date: 2026-07-13
    decided_by: user
    statement: "The decision log ships as three layers: a shared convention doc (shared/decision-log.md) wired into the lifecycle skills' capture points, a model-only skill (skills/decision-log/) for ad-hoc conversational decisions, and a /sdd-planner:decide command for manual record/lookup/reconcile."
    rejected: [hook-based capture, capture via an MCP server]
    rationale: "Claude Code has no hook that fires when a user answers a question (verified against docs 2026-07-12), so capture must be behavioral — matching how the plugin already enforces its contracts."
    scope: []
    tags: [decision-log, architecture, claude-code]
    reversibility: two-way
  - id: D-0003
    kind: decision
    status: accepted
    date: 2026-07-13
    decided_by: user
    statement: "A new decision that contradicts or supersedes an accepted ledger entry always stops for user reconciliation — collisions are never auto-resolved and never settled by recency."
    rejected: [precedence-based silent resolution, recency-wins]
    rationale: "Every surveyed tool that resolves conflicts silently hides real contradictions; the ADR tradition insists the human owns supersession."
    scope: []
    tags: [decision-log, collision-detection]
    reversibility: one-way
  - id: D-0004
    kind: decision
    status: accepted
    date: 2026-07-13
    decided_by: user
    supersedes: D-0001
    statement: "Decisions live with the repo they represent: the ledger is <planning-root>/Decisions/decisions.md when the planning root is inside the repo, and <repo-root>/DECISIONS.md when the planning root is external — there is no cross-repo global ledger."
    rejected: [cross-repo global ledger in an external planning root, per-repo scoping tags inside one shared ledger]
    rationale: "Each repo's truths stay versioned with its code; one repo's decisions never bleed into another. Supersedes D-0001's single-canonical-ledger wording; the decisions[] format and in-repo common case are unchanged."
    scope: []
    tags: [decision-log, architecture, multi-repo]
    reversibility: two-way
  - id: D-0005
    kind: decision
    status: accepted
    date: 2026-07-13
    decided_by: user
    statement: "The plugin ships a SessionStart hook in v1 (hooks/hooks.json + hooks/load-decisions.sh) that injects accepted ledger entries as additionalContext at session start."
    rejected: [deferring the hook until behavioral capture proves out]
    rationale: "Guarantees recall of accepted decisions even in sessions that skip onboarding, at a small per-session context cost; the script is a silent no-op when no ledger exists."
    scope: []
    tags: [decision-log, hooks, claude-code]
    reversibility: two-way
  - id: D-0006
    kind: decision
    status: accepted
    date: 2026-07-13
    decided_by: user
    statement: "The sdd-dashboard companion plugin gets no decisions view for now; /decide list and search cover lookup needs."
    rejected: [dashboard decisions panel in v1]
    rationale: "The ledger is small and text-first; revisit if ledgers grow or users ask for visual browsing."
    scope: []
    tags: [decision-log, dashboard]
    reversibility: two-way
---

# Decision Ledger

Machine-readable record of decided truths — design choices, concept definitions, answered design questions. The frontmatter `decisions[]` array is canonical; see `shared/decision-log.md` in the plugin for the entry schema, lifecycle rules, and collision procedure.

Entries are append-only: an accepted entry is never edited except to mark it superseded. A change of mind is a new entry that supersedes the old one.
