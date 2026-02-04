#!/bin/bash
# generate-start-instructions.sh - Generate instructions for starting the loop
# Part of dr-done v2 plugin

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

init_dr_done

# Get current state
STATE_OUTPUT=$("$SCRIPT_DIR/read-state.sh")

# Get pending tasks
PENDING_OUTPUT=$("$SCRIPT_DIR/find-tasks.sh" pending --limit 5)

cat << EOF
**Current state:** $STATE_OUTPUT

**Pending tasks:** $PENDING_OUTPUT

## Checks

1. If state shows a non-null looper that isn't \`\${CLAUDE_SESSION_ID}\`, stop with error: "Another session is already processing the queue"
2. If no pending tasks exist (shows "(none)"), stop with error: "No pending tasks. Use /dr-done:add first."

## Start the loop

Write \`.dr-done/state.json\`:
\`\`\`json
{"looper": "\${CLAUDE_SESSION_ID}", "iteration": 0}
\`\`\`

Then follow this prompt:

EOF

# Generate the loop prompt
"$SCRIPT_DIR/generate-loop-prompt.sh"
