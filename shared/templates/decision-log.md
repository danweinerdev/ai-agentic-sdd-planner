---
title: "Decision Ledger"
type: decision-log
status: active
created: {{DATE}}
updated: {{DATE}}
tags: [decisions]
related: []
decisions: []
---

# Decision Ledger

Machine-readable record of decided truths — design choices, concept definitions, answered design questions. The frontmatter `decisions[]` array is canonical; see `shared/decision-log.md` in the plugin for the entry schema, lifecycle rules, and collision procedure.

Entries are append-only: an accepted entry is never edited except to mark it superseded. A change of mind is a new entry that supersedes the old one.

<!-- Optional extended context per entry:

## D-0001 — Short Title

Options considered, links, deeper deliberation. The frontmatter entry remains canonical.
-->
