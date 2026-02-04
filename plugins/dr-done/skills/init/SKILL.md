---
name: init
description: Initialize the dr-done task automation system
context: fork
---

!`${CLAUDE_PLUGIN_ROOT}/scripts/init.sh --with-config`

We just ran the init script to create the dr-done directory structure.

Report what was created:

- `.dr-done/` directory
- `.dr-done/tasks/` subdirectory
- `.dr-done/.gitignore` (excludes tasks/ from git)
- `.dr-done/config.json` (if it didn't exist)
