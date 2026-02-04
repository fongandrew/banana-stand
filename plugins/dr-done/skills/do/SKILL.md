---
name: do
description: Add a task and immediately start processing
argument-hint: <task description>
disable-model-invocation: true
---

!`${CLAUDE_PLUGIN_ROOT}/scripts/init.sh`

!`${CLAUDE_PLUGIN_ROOT}/scripts/generate-add-instructions.sh`

!`${CLAUDE_PLUGIN_ROOT}/scripts/generate-start-instructions.sh`
