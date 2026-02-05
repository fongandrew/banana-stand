#!/bin/bash
# session-start-hook.sh - Re-inject loop prompt on session resume
# Part of dr-done v2 plugin

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/template.sh"

# Read input from stdin
INPUT=$(cat)

# Get session ID from input and export to CLAUDE_ENV_FILE
SESSION_ID=$(get_session_id_from_input "$INPUT")
if [[ -n "$SESSION_ID" && -n "$CLAUDE_ENV_FILE" ]]; then
    echo "export CLAUDE_SESSION_ID=$SESSION_ID" >> "$CLAUDE_ENV_FILE"
fi

init_dr_done

# Debug logging
LOG_FILE="$DR_DONE_DIR/session-start-hook.log"
{
    echo "=== Session start hook called at $(date) ==="
    echo "SESSION_ID from input: $SESSION_ID"
    echo "CLAUDE_ENV_FILE: ${CLAUDE_ENV_FILE:-not set}"
    echo "State file exists: $([ -f "$STATE_FILE" ] && echo "yes" || echo "no")"
} >> "$LOG_FILE"

# No state file = not active
if [[ ! -f "$STATE_FILE" ]]; then
    echo "No state file, exiting" >> "$LOG_FILE"
    exit 0
fi
if [[ -z "$SESSION_ID" ]]; then
    echo "No session ID, exiting" >> "$LOG_FILE"
    exit 0
fi

# Log current looper from state file
CURRENT_LOOPER=$(jq -r '.looper // "null"' "$STATE_FILE" 2>/dev/null)
echo "Current looper in state file: $CURRENT_LOOPER" >> "$LOG_FILE"
echo "Checking if $SESSION_ID is the looper..." >> "$LOG_FILE"

# Not the looper = no injection needed
if ! is_looper "$SESSION_ID"; then
    echo "Not the looper, exiting" >> "$LOG_FILE"
    exit 0
fi

echo "We are the looper! Re-injecting prompt..." >> "$LOG_FILE"

# Read config and get next task
read_config
get_next_task

echo "Next task type: $NEXT_TASK_TYPE, file: $NEXT_TASK_FILE" >> "$LOG_FILE"

case "$NEXT_TASK_TYPE" in
    review)
        echo "Injecting review prompt" >> "$LOG_FILE"
        echo "[dr-done] Session resumed. Task ready for review."
        echo ""
        build_review_prompt "$NEXT_TASK_FILE"
        ;;
    pending)
        echo "Injecting pending task prompt" >> "$LOG_FILE"
        echo "[dr-done] Session resumed. Continue with the loop:"
        echo ""
        build_pending_prompt "$NEXT_TASK_FILE"
        ;;
    *)
        echo "No tasks to inject (type: $NEXT_TASK_TYPE)" >> "$LOG_FILE"
        echo "[dr-done] Session resumed. All tasks complete."
        ;;
esac
