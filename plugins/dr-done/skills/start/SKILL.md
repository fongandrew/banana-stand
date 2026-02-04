---
name: start
description: Start processing tasks from the dr-done queue
disable-model-invocation: true
---

!`${CLAUDE_PLUGIN_ROOT}/scripts/init.sh`

!`${CLAUDE_PLUGIN_ROOT}/scripts/generate-start-instructions.sh`
