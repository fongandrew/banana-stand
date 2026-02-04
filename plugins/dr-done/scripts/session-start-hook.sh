#!/bin/bash
# session-start-hook.sh - Re-inject loop prompt on session resume
# Part of dr-done v2 plugin

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/template.sh"

# Read input from stdin
INPUT=$(cat)

init_dr_done

# No state file = not active
if [[ ! -f "$STATE_FILE" ]]; then
    exit 0
fi

# Get session ID from input
SESSION_ID=$(get_session_id_from_input "$INPUT")
if [[ -z "$SESSION_ID" ]]; then
    exit 0
fi

# Not the looper = no injection needed
if ! is_looper "$SESSION_ID"; then
    exit 0
fi

# Read config and get next task
read_config
get_next_task

case "$NEXT_TASK_TYPE" in
    review)
        echo "[dr-done] Session resumed. Task ready for review."
        echo ""
        build_review_prompt "$NEXT_TASK_FILE"
        ;;
    pending)
        echo "[dr-done] Session resumed. Continue with the loop:"
        echo ""
        build_pending_prompt "$NEXT_TASK_FILE"
        ;;
    *)
        echo "[dr-done] Session resumed. All tasks complete."
        ;;
esac
