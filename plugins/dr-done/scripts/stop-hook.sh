#!/bin/bash
# stop-hook.sh - Stop hook for main loop control
# Part of dr-done v2 plugin

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/template.sh"

# Read input from stdin
INPUT=$(cat)

init_dr_done

# No state file = not active, allow stop
if [[ ! -f "$STATE_FILE" ]]; then
    exit 0
fi

# Get session ID from input
SESSION_ID=$(get_session_id_from_input "$INPUT")
if [[ -z "$SESSION_ID" ]]; then
    # No session ID means we can't check looper status, allow stop
    exit 0
fi

# Not the looper = allow stop
if ! is_looper "$SESSION_ID"; then
    exit 0
fi

# We are the looper - increment iteration
new_iteration=$(increment_iteration)

# Read config
read_config

# Max iterations exceeded - clear looper and allow stop
if [[ $new_iteration -gt $CONFIG_MAX_ITERATIONS ]]; then
    clear_looper
    echo "[dr-done] Max iterations ($CONFIG_MAX_ITERATIONS) reached. Loop stopped." >&2
    exit 0
fi

# Check for uncommitted changes (if gitCommit enabled)
if [[ "$CONFIG_GIT_COMMIT" == "true" ]] && has_uncommitted_changes; then
    output_block "You have uncommitted changes. Please commit your work before continuing."
    exit 0
fi

# Get next task and handle accordingly
get_next_task

case "$NEXT_TASK_TYPE" in
    review)
        output_block "Task ready for review. $(build_review_prompt "$NEXT_TASK_FILE")"
        ;;
    pending)
        output_block "$(build_pending_prompt "$NEXT_TASK_FILE")"
        ;;
    stuck)
        stuck_count=$(find_stuck_tasks | wc -l | tr -d ' ')
        clear_looper
        echo "[dr-done] $stuck_count stuck task(s) need attention. Use /dr-done:unstick to retry." >&2
        ;;
    complete)
        clear_looper
        echo "[dr-done] All tasks complete. Loop stopped." >&2
        ;;
esac
