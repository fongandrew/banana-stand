---
name: add
description: Add a new task to the dr-done queue
argument-hint: <task description>
context: fork
---

!`${CLAUDE_PLUGIN_ROOT}/scripts/init.sh`

!`${CLAUDE_PLUGIN_ROOT}/scripts/generate-add-instructions.sh`

Just add the task. Do not start working on the task yet until you are explicitly told to.
