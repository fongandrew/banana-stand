#!/bin/bash
# generate-start-instructions.sh - Generate instructions for starting the loop
#
# Usage: generate-start-instructions.sh [--focus-new]
#
# Options:
#   --focus-new  Skip pending task check and generate instructions for working
#                on a newly created task file (used by /do)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/template.sh"

init_dr_done
read_config

# Parse arguments
FOCUS_NEW=false
for arg in "$@"; do
    case "$arg" in
        --focus-new)
            FOCUS_NEW=true
            ;;
    esac
done

# Check for pending tasks (skip if --focus-new)
if [[ "$FOCUS_NEW" == "false" ]]; then
    PENDING_OUTPUT=$("$SCRIPT_DIR/find-tasks.sh" pending --limit 1)
    if [[ "$PENDING_OUTPUT" == "(none)" ]]; then
        cat << 'EOF'
**Error:** No pending tasks. Use /dr-done:add first.
EOF
        exit 0
    fi
fi

# Read current looper from state
CURRENT_LOOPER=""
if [[ -f "$STATE_FILE" ]]; then
    CURRENT_LOOPER=$(jq -r '.looper // empty' "$STATE_FILE" 2>/dev/null || echo "")
fi

# Generate set-focus instruction for --focus-new mode
if [[ "$FOCUS_NEW" == "true" ]]; then
    cat << 'EOF'
After creating the task file, set focus to it:
```bash
plugins/dr-done/scripts/set-focus.sh <the-file-you-created>
```

EOF
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

# Generate the loop prompt (or focus-new prompt)
if [[ "$FOCUS_NEW" == "true" ]]; then
    # Generate prompt for the newly created file
    done_extension=""
    review_instruction=""
    commit_instruction=""

    if [[ "$CONFIG_REVIEW" == "true" ]]; then
        done_extension=".review.md"
        review_instruction="- If complete, spawn the dr-done:reviewer subagent and have it review the renamed file."
    else
        done_extension=".done.md"
    fi

    if [[ "$CONFIG_GIT_COMMIT" == "true" ]]; then
        commit_instruction="- Commit your changes with a descriptive message"
    fi

    cat << EOF
Work on the task file you just created.

- Re-read the file if needed.
- Check TaskList tool for existing open subtasks.
- Do a meaningful amount of work.
- Append work summary to the file, then rename:
    - \`$done_extension\` = complete
    - \`.stuck.md\` = need help
    - \`.md\` = more work needed
$commit_instruction
$review_instruction
EOF
else
    "$SCRIPT_DIR/generate-loop-prompt.sh"
fi
