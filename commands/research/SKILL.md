---
name: research
description: "Investigate a topic and produce a structured research document. Triggers: /research, research this, investigate, look into"
---

# /research — Investigate a Topic

## Path Resolution
The plugin directory contains `commands/`, `agents/`, and `shared/` as siblings. Find it by globbing for `**/commands/research/SKILL.md` in both the current directory and `~/.claude/plugins/cache/`; if multiple versions match, sort them as **semantic versions** (like `sort -V`) and use the highest, then strip `commands/research/SKILL.md` from the match. Resolve the planning root (artifacts) and target repository per `shared/path-resolution.md` in the plugin directory.

## When to Use
When you need to gather and synthesize information about a topic before making decisions. Good for technology evaluations, understanding existing systems, or exploring unknowns.

## Process

1. **Define Scope**
   - If the user hasn't already specified it, ask what topic to research and what questions need answering
   - Determine if this is codebase research, external research, or both

2. **Gather Information**
   - Invoke the `sdd-planner:researcher` agent with the topic and questions
   - The agent will scan existing artifacts, codebase, and web as needed

3. **Synthesize**
   - Create `Research/<topic-slug>.md` using `shared/templates/research.md` (`<topic-slug>` is lowercase kebab-case, e.g., `auth-token-rotation`)
   - Organize findings into Context, Key Insights, Sources, Analysis
   - Highlight implications and recommendations
   - List open questions that remain

4. **Link**
   - Add cross-references to related artifacts in the `related` frontmatter field

5. **Finalize**
   - Set `status: active` in the frontmatter once the document is complete and presented to the user. Then re-read the frontmatter and confirm it parses as YAML and includes `title`, `type`, `status`, `created`, `updated`, `tags`, `related`.

## Output
```
Research/<topic-slug>.md
```

## Document Structure
See `shared/templates/research.md`:
- **Context**: Why this research is needed
- **Findings**: Key insights and sources
- **Analysis**: Implications and recommendations
- **Open Questions**: What remains unknown

## Context
- Orchestration: `shared/orchestration.md`
- Template: `shared/templates/research.md`
- Schema: `shared/frontmatter-schema.md`
- Agent: `sdd-planner:researcher`
