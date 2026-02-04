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

# Read current looper from state
CURRENT_LOOPER=""
if [[ -f "$STATE_FILE" ]]; then
    CURRENT_LOOPER=$(jq -r '.looper // empty' "$STATE_FILE" 2>/dev/null || echo "")
fi

cat << EOF
**Current state:** $STATE_OUTPUT

**Pending tasks:** $PENDING_OUTPUT

## Checks

EOF

# Check for no pending tasks
if [[ "$PENDING_OUTPUT" == "(none)" ]]; then
    cat << 'EOF'
**Error:** No pending tasks. Use /dr-done:add first.
EOF
    exit 0
fi

# Generate appropriate instructions based on looper state
if [[ -z "$CURRENT_LOOPER" || "$CURRENT_LOOPER" == "null" ]]; then
    # No active looper - can start immediately
    cat << 'EOF'
No active looper. Ready to start.

## Start the loop

Run:
```bash
plugins/dr-done/scripts/set-looper.sh "$CLAUDE_SESSION_ID"
```

Then follow this prompt:

EOF
else
    # There's an existing looper - need conditional handling
    cat << EOF
**Existing looper detected:** \`$CURRENT_LOOPER\`

## Before starting

Check if \`$CURRENT_LOOPER\` equals your \`\$CLAUDE_SESSION_ID\`:

- **If they match:** You are resuming your own loop. Proceed to start.
- **If they don't match:** Another session may be active. Use the AskUserQuestion tool to ask:
  - Question: "Another session ($CURRENT_LOOPER) is registered as the active looper. Override and take over the loop?"
  - Options: "Yes, take over" / "No, cancel"
  - If user says no, stop and do not proceed.

## Start the loop

Run:
\`\`\`bash
plugins/dr-done/scripts/set-looper.sh "\$CLAUDE_SESSION_ID"
\`\`\`

Then follow this prompt:

EOF
fi

# Generate the loop prompt
"$SCRIPT_DIR/generate-loop-prompt.sh"
