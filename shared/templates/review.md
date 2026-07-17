---
title: "{{REVIEW_TYPE}}: {{TARGET_TITLE}}"
type: review
status: open
created: {{DATE}}
updated: {{DATE}}
tags: [review]
related: [{{TARGET_PATH}}]
review_of: "{{TARGET_PATH}}"
rev: "{{REV}}"
findings: []
# Each finding entry:
#   id: F-01              # stable within this file; never renumbered
#   severity: critical    # critical | major | minor | question
#   title: "One-line finding"
#   status: open          # open | fixed | deferred | rejected | answered
followups: []
# Each follow-up entry (created when a finding is deferred without a plan task):
#   id: FU-01
#   finding: F-01
#   summary: "What still needs doing"
#   tracked_in: ""        # task id once landed in a plan; empty = floating
---

# {{REVIEW_TYPE}}: {{TARGET_TITLE}}

**Reviewed state:** {{REV}}
**Review mode:** {{MODE}}

## Findings

### F-01 — [Severity] One-line finding
**Impugns:** [FR-NN / AC-NN / task N.M / D-NNNN / file:line]
**Scenario:** The concrete sequence of events, inputs, or conditions that exposes the flaw.
**Why it matters:** Impact if unaddressed.
**Recommendation:** Concrete mitigation or the question to resolve.

## Resolution Log

<!-- Append-only; one entry per disposition. Update the finding's status in
     findings[] to match. See shared/review-artifacts.md.

### F-01 — fixed (YYYY-MM-DD)
What was decided and done; governing facts by id; commit/task/D-NNNN links.
-->
