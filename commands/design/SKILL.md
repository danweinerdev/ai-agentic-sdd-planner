---
name: design
description: "Create a technical architecture and design document. Do NOT enter plan mode — this skill produces a design artifact directly. Triggers: /design, design this, architecture for, technical design"
---

# /design — Technical Architecture Document

## Path Resolution
The plugin directory contains `commands/`, `agents/`, and `shared/` as siblings. Find it by globbing for `**/commands/research/SKILL.md` in both the current directory and `~/.claude/plugins/cache/`; if multiple versions match, sort them as **semantic versions** (like `sort -V`) and use the highest, then strip `commands/research/SKILL.md` from the match. Resolve the planning root (artifacts) and target repository per `shared/path-resolution.md` in the plugin directory.

## When to Use
When you need to define the technical architecture for a component or system before implementation. Produces a reviewable design document with architecture decisions.

## Process

1. **Gather Context**
   - If the user hasn't already specified it, ask what component to design
   - Invoke `sdd-planner:researcher` with the component and its constraints; it scans all artifact directories and the codebase per its own definition.
   - Review any related research documents

2. **Draft Design**
   - Create `Designs/<ComponentName>/README.md` using `shared/templates/design.md`
   - Document: overview, architecture (components, data flow, interfaces), design decisions (with alternatives considered), error handling, testing strategy, migration plan
   - **Use Mermaid diagrams** for architecture, data flow, and component relationships — prefer `graph TD`, `flowchart LR`, or `sequenceDiagram` over ASCII art or prose-only descriptions
   - **Testing strategy must include structural verification:** Read `shared/language-verification.md` and include the language-appropriate structural checks (sanitizers, static analysis, type checking) in the Testing Strategy section. These define what "structurally correct" means for this component beyond passing tests.
   - Set status to `draft`

3. **Review**
   - Set `status: review` when dispatching the reviewer
   - Invoke the `sdd-planner:plan-reviewer` agent to review the design
   - Address critical and major issues

4. **Present for Approval**
   - Show the user the review results and final design
   - **Open questions gate approval.** Before setting `status: approved`, every remaining open question must be either resolved or explicitly marked **non-blocking** with a one-line rationale for why the design holds regardless of its answer. A question whose answer could change the architecture blocks approval — leave the design at `review` and name the question to the user. A "⚠️ pending confirmation" annotation is not a gate.
   - After findings are addressed and the user explicitly approves, set `status: approved`. If the user declines or defers, leave it at `review`.
   - Then re-read the frontmatter and confirm it parses as YAML and includes `title`, `type`, `status`, `created`, `updated`, `tags`, `related`.

## Output
```
Designs/<ComponentName>/README.md
```

## Document Structure
See `shared/templates/design.md`:
- **Overview**: Component role in the system
- **Architecture**: Components, data flow, interfaces
- **Design Decisions**: Each with context, options, decision, rationale
- **Error Handling**: Detection, reporting, recovery
- **Testing Strategy**: How to validate
- **Migration / Rollout**: Transition plan

## Context
- Orchestration: `shared/orchestration.md`
- Template: `shared/templates/design.md`
- Schema: `shared/frontmatter-schema.md`
- Agents: `sdd-planner:researcher`, `sdd-planner:plan-reviewer`
