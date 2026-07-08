---
name: retro
description: "Capture learnings and reflections in a retrospective. Triggers: /retro, retrospective, what did we learn, lessons learned"
---

# /retro — Capture Learnings

## Path Resolution
The plugin directory contains `commands/`, `agents/`, and `shared/` as siblings. Find it by globbing for `**/commands/research/SKILL.md` in both the current directory and `~/.claude/plugins/cache/`; if multiple versions match, sort them as **semantic versions** (like `sort -V`) and use the highest, then strip `commands/research/SKILL.md` from the match. Resolve the planning root (artifacts) and target repository per `shared/path-resolution.md` in the plugin directory.

## When to Use
After completing a significant piece of work (a plan, a sprint, a milestone) to capture what went well, what could be improved, and action items for the future.

## Process

1. **Determine Scope**
   - Ask what period or work to reflect on
   - Generate a slug for the filename

2. **Gather Input**
   - Ask the user about:
     - What went well
     - What could be improved
     - Any key metrics or outcomes
   - Review recent debriefs from `Plans/*/notes/` for context (filter to plans whose frontmatter `status` is `active` or `complete`; include `archived` plans only if the retro period explicitly covers them) — and specifically look at each debrief's **Skill Opportunities** section to aggregate patterns that showed up across multiple phases

3. **Spot Skill Opportunities**
   A retro spans a larger window than a single debrief, so skill opportunities here are often richer — patterns that repeated across phases, across plans, or across team members. Look for:
   - Patterns that appeared in more than one debrief's Skill Opportunities section (strong signal — already observed twice)
   - Slash-command sequences that always went together across the period
   - Investigations or workflows people re-derived because there was nowhere to put the knowledge
   - Codebase operations that lacked automation and cost time in multiple tasks
   - Checks, validations, or reviews that happened mentally and should have been automated

   For each opportunity, capture: the pattern and how often it came up, where the skill should live (new `/sdd-planner:*` slash command, a project-level Claude skill, a codebase helper, a shell script, a Makefile target), why a skill helps, and a rough shape (inputs, outputs, when to invoke, which agents or tools it wraps). Include enough detail for a future session to act on it without re-deriving the context.

   Ask the user to confirm, prune, or extend the list before writing.

4. **Write Retrospective**
   - Create `Retro/YYYY-MM-DD-<slug>.md` using `shared/templates/retro.md`
   - Date is today's date
   - Fill in: What Went Well, What Could Be Improved, Action Items, Key Metrics, **Skill Opportunities**, Takeaways
   - Set status to `draft` (user can mark `complete` after review)

5. **Link**
   - Add references to related plans or debriefs in `related` frontmatter

## Output
```
Retro/YYYY-MM-DD-<slug>.md
```

## Document Structure
See `shared/templates/retro.md`:
- **What Went Well**: Things to continue doing
- **What Could Be Improved**: Things to change
- **Action Items**: Specific, actionable improvements (checklist)
- **Key Metrics**: Quantitative outcomes
- **Skill Opportunities**: Repeated patterns across the period that should become reusable skills
- **Takeaways**: Summary of key lessons

## Context
- Template: `shared/templates/retro.md`
- Schema: `shared/frontmatter-schema.md`
- Retro directory: `Retro/`
