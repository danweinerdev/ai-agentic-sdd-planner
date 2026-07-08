---
name: specify
description: "Write a requirements specification for a feature. Do NOT enter plan mode — this skill produces a spec artifact directly. Triggers: /specify, write spec, specify requirements, requirements for"
---

# /specify — Write Requirements Specification

## Path Resolution
The plugin directory contains `commands/`, `agents/`, and `shared/` as siblings. Find it by globbing for `**/commands/research/SKILL.md` in both the current directory and `~/.claude/plugins/cache/`; if multiple versions match, sort them as **semantic versions** (like `sort -V`) and use the highest, then strip `commands/research/SKILL.md` from the match. Resolve the planning root (artifacts) and target repository per `shared/path-resolution.md` in the plugin directory.

## When to Use
When you need to define the requirements for a feature before designing or implementing it. Produces a testable, reviewable specification.

## Process

1. **Gather Context**
   - If the user hasn't already specified it, ask what feature to specify
   - Invoke the `sdd-planner:researcher` agent to gather context from existing artifacts and codebase
   - Review any related research or brainstorm documents

2. **Draft Specification**
   - Create `Specs/<FeatureName>/README.md` using `shared/templates/spec.md`
   - Write: overview, goals, non-goals, requirements (functional + non-functional), user stories, acceptance criteria, constraints, dependencies
   - Set status to `draft`

3. **Review**
   - Set `status: review` when dispatching the reviewer
   - Invoke the `sdd-planner:spec-reviewer` agent to review the specification
   - Address critical and major issues

4. **Present for Approval**
   - Show the user the review results and final spec
   - After findings are addressed and the user explicitly approves, set `status: approved`. If the user declines or defers, leave it at `review`.
   - Then re-read the frontmatter and confirm it parses as YAML and includes `title`, `type`, `status`, `created`, `updated`, `tags`, `related`.

## Output
```
Specs/<FeatureName>/README.md
```

## Document Structure
See `shared/templates/spec.md`:
- **Overview**: Feature purpose
- **Goals / Non-Goals**: Scope boundaries
- **Requirements**: Functional and non-functional
- **User Stories**: As a [user], I want to...
- **Acceptance Criteria**: Testable pass/fail criteria
- **Constraints / Dependencies / Open Questions**

## Context
- Orchestration: `shared/orchestration.md`
- Template: `shared/templates/spec.md`
- Schema: `shared/frontmatter-schema.md`
- Agents: `sdd-planner:researcher`, `sdd-planner:spec-reviewer`
