#!/bin/bash
# generate-start-instructions.sh - Generate instructions for starting the loop
# Part of dr-done v2 plugin

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

init_dr_done

# Check for pending tasks
PENDING_OUTPUT=$("$SCRIPT_DIR/find-tasks.sh" pending --limit 1)
if [[ "$PENDING_OUTPUT" == "(none)" ]]; then
    cat << 'EOF'
**Error:** No pending tasks. Use /dr-done:add first.
EOF
    exit 0
fi

# Read current looper from state
CURRENT_LOOPER=""
if [[ -f "$STATE_FILE" ]]; then
    CURRENT_LOOPER=$(jq -r '.looper // empty' "$STATE_FILE" 2>/dev/null || echo "")
fi

# Generate appropriate instructions based on looper state
if [[ -z "$CURRENT_LOOPER" || "$CURRENT_LOOPER" == "null" ]]; then
    # No active looper - can start immediately
    cat << EOF
Run:
\`\`\`bash
plugins/dr-done/scripts/set-looper.sh "$CLAUDE_SESSION_ID"
\`\`\`

Then follow this prompt:

EOF
else
    # There's an existing looper - need conditional handling
    if [[ "$CURRENT_LOOPER" == "$CLAUDE_SESSION_ID" ]]; then
        cat << EOF
You are resuming your own loop.

First, reset iteration count:
\`\`\`bash
plugins/dr-done/scripts/set-looper.sh "$CLAUDE_SESSION_ID"
\`\`\`

Then follow this prompt:

EOF
    else
        cat << EOF
**Existing looper detected:** \`$CURRENT_LOOPER\`

**Your session:** \`$CLAUDE_SESSION_ID\`

Another session is registered as the active looper. Use the AskUserQuestion tool to ask:
- Question: "Another session ($CURRENT_LOOPER) is registered as the active looper. Override and take over the loop?"
- Options: "Yes, take over" / "No, cancel"
- If user says no, stop and do not proceed.

## Start the loop

Run:
\`\`\`bash
plugins/dr-done/scripts/set-looper.sh "$CLAUDE_SESSION_ID"
\`\`\`

Then follow this prompt:

EOF
    fi
fi

# Generate the loop prompt
"$SCRIPT_DIR/generate-loop-prompt.sh"
