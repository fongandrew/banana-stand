#!/bin/bash
# session-start-hook.sh - Re-inject loop prompt on session resume

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

# No state file = not active
if [[ ! -f "$STATE_FILE" ]]; then
    log_debug "$SESSION_ID" "session-start: no state file, exiting"
    exit 0
fi

if [[ -z "$SESSION_ID" ]]; then
    log_debug "$SESSION_ID" "session-start: no session ID, exiting"
    exit 0
fi

# Not the looper = no injection needed
if ! is_looper "$SESSION_ID"; then
    log_debug "$SESSION_ID" "session-start: not looper, skipping injection"
    exit 0
fi

log_debug "$SESSION_ID" "session-start: is looper, re-injecting prompt"

# Read config and get next task
read_config
get_next_task

case "$NEXT_TASK_TYPE" in
    review)
        log_debug "$SESSION_ID" "session-start: injecting review task"
        echo "[dr-done] Session resumed. Task ready for review."
        echo ""
        build_review_prompt "$NEXT_TASK_FILE"
        ;;
    pending)
        log_debug "$SESSION_ID" "session-start: injecting pending task"
        echo "[dr-done] Session resumed. Continue with the loop:"
        echo ""
        build_pending_prompt "$NEXT_TASK_FILE"
        ;;
    *)
        log_debug "$SESSION_ID" "session-start: no tasks, type=$NEXT_TASK_TYPE"
        echo "[dr-done] Session resumed. All tasks complete."
        ;;
esac
