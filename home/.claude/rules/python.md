---
paths:
  - "**/*.{py,pyi}"
---

# Python

Before you change any Python file, call the Skill tool with skill: "python-anti-patterns" and check the change against its checklist. For tooling - dependencies, the linter, how to run things - call it with skill: "modern-python" as well. Type check with ty (`uv run ty check`, or `uvx ty check` outside a project), unless the repo's config already sets up another checker. Where the repo's own conventions differ from either skill, the repo wins.
