---
name: python-specifications
description: "Structural verification for Python — type checker (mypy/pyright), linter (ruff/flake8). Load when planning, implementing, or reviewing Python code (.py; pyproject.toml, setup.cfg, ruff.toml)."
disable-model-invocation: true
---

# Python — Structural Verification

## Tools

| Tool | When | What it catches |
|------|------|-----------------|
| Type checker (mypy / pyright) | Project uses type annotations | Type mismatches, missing attributes, incorrect signatures |
| Linter (ruff / flake8) | If configured in project | Unused imports, undefined names, common bugs |

## Minimum Bar

Run the type checker if the project has type annotations or a `py.typed` marker. Run the linter if configured (check `pyproject.toml`, `setup.cfg`, `ruff.toml`).
