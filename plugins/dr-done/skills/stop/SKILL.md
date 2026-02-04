---
name: stop
description: Stop processing the dr-done task queue
context: fork
---

**Result:** !`${CLAUDE_PLUGIN_ROOT}/scripts/stop.sh ${CLAUDE_SESSION_ID}`

Based on the result above:

- `stopped` - Report: "Loop stopped."
- `no-looper` - Report: "No active looper. Nothing to stop."
- `other-session:<id>` - Use AskUserQuestion to ask the user if they want to stop that other session. If yes, run the stop script again with that session ID: `${CLAUDE_PLUGIN_ROOT}/scripts/stop.sh <id>`
