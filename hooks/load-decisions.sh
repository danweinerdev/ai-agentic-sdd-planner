#!/usr/bin/env bash
# SessionStart hook: inject accepted decision-ledger entries as additionalContext.
# Silent no-op on any failure — a broken hook must never break a session.
set -u
command -v python3 >/dev/null 2>&1 || exit 0

exec python3 - <<'PYEOF'
import json, os, re, sys

MAX_ENTRIES = 30

def find_ledger():
    """Resolve the ledger per shared/decision-log.md § Ledger location."""
    project = os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()
    # Walk up from the project dir looking for planning-config.json.
    d = os.path.abspath(project)
    config_dir, planning_root = None, "."
    while True:
        cfg = os.path.join(d, "planning-config.json")
        if os.path.isfile(cfg):
            try:
                with open(cfg) as f:
                    planning_root = json.load(f).get("planningRoot") or "."
                config_dir = d
            except Exception:
                pass
            break
        parent = os.path.dirname(d)
        if parent == d:
            break
        d = parent
    candidates = []
    if config_dir is not None:
        root = planning_root if os.path.isabs(planning_root) else os.path.join(config_dir, planning_root)
        candidates.append(os.path.join(root, "Decisions", "decisions.md"))
    # External-planning-root / no-config cases: repo-local ledger.
    candidates.append(os.path.join(project, "DECISIONS.md"))
    candidates.append(os.path.join(project, "Decisions", "decisions.md"))
    for c in candidates:
        if os.path.isfile(c):
            return c
    return None

def parse_entries(path):
    """Minimal parser for the template-controlled decisions[] frontmatter array.

    Not a YAML parser on purpose: PyYAML isn't stdlib and the ledger format is
    template-controlled. Splits the frontmatter into '- id:' blocks and pulls
    scalar fields by regex.
    """
    text = open(path, encoding="utf-8", errors="replace").read()
    m = re.match(r"^---\n(.*?)\n---(\n|$)", text, re.S)
    if not m:
        return []
    front = m.group(1)
    entries = []
    for block in re.split(r"\n\s*- id:", front)[1:]:
        block = "id:" + block
        def field(name):
            fm = re.search(rf"^\s*{name}:\s*(.+?)\s*$", block, re.M)
            return fm.group(1).strip().strip('"').strip("'") if fm else ""
        entries.append({k: field(k) for k in ("id", "status", "statement", "kind")})
    return entries

ledger = find_ledger()
if not ledger:
    sys.exit(0)
try:
    accepted = [e for e in parse_entries(ledger) if e["status"] == "accepted" and e["statement"]]
except Exception:
    sys.exit(0)
if not accepted:
    sys.exit(0)

lines = [f"- {e['id']}: {e['statement']}" for e in accepted[:MAX_ENTRIES]]
if len(accepted) > MAX_ENTRIES:
    lines.append(f"- ... {len(accepted) - MAX_ENTRIES} more accepted entries in the ledger")
context = (
    f"## Decision Ledger ({ledger})\n"
    "Accepted decisions — standing constraints on planning and implementation. "
    "A new decision that contradicts one must stop for user reconciliation "
    "(see shared/decision-log.md in the sdd-planner plugin):\n" + "\n".join(lines)
)
print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": context}}))
PYEOF
