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

# Get session ID from input
SESSION_ID=$(get_session_id_from_input "$INPUT")

# No state file = not active, allow stop
if [[ ! -f "$STATE_FILE" ]]; then
    log_debug "$SESSION_ID" "stop: no state file, allowing"
    exit 0
fi

if [[ -z "$SESSION_ID" ]]; then
    log_debug "$SESSION_ID" "stop: no session ID, allowing"
    exit 0
fi

# Not the looper = allow stop
if ! is_looper "$SESSION_ID"; then
    log_debug "$SESSION_ID" "stop: not looper, allowing"
    exit 0
fi

log_debug "$SESSION_ID" "stop: looper attempting stop"

# We are the looper - increment iteration
new_iteration=$(increment_iteration)

# Read config
read_config

# Max iterations exceeded - clear looper and allow stop
if [[ $new_iteration -gt $CONFIG_MAX_ITERATIONS ]]; then
    log_debug "$SESSION_ID" "stop: max iterations ($CONFIG_MAX_ITERATIONS) reached, clearing looper"
    clear_looper
    echo "[dr-done] Max iterations ($CONFIG_MAX_ITERATIONS) reached. Loop stopped." >&2
    exit 0
fi

# Check for uncommitted changes (if gitCommit enabled)
if [[ "$CONFIG_GIT_COMMIT" == "true" ]] && has_uncommitted_changes; then
    log_debug "$SESSION_ID" "stop: uncommitted changes, blocking"
    output_block "You have uncommitted changes. Please commit your work before continuing."
    exit 0
fi

# Get next task and handle accordingly
get_next_task

case "$NEXT_TASK_TYPE" in
    review)
        log_debug "$SESSION_ID" "stop: blocking for review task"
        output_block "Task ready for review. $(build_review_prompt "$NEXT_TASK_FILE")"
        ;;
    pending)
        log_debug "$SESSION_ID" "stop: blocking for pending task"
        output_block "$(build_pending_prompt "$NEXT_TASK_FILE")"
        ;;
    stuck)
        stuck_count=$(find_stuck_tasks | wc -l | tr -d ' ')
        log_debug "$SESSION_ID" "stop: stuck tasks ($stuck_count), clearing looper"
        clear_looper
        echo "[dr-done] $stuck_count stuck task(s) need attention. Use /dr-done:unstick to retry." >&2
        ;;
    complete)
        log_debug "$SESSION_ID" "stop: all complete, clearing looper"
        clear_looper
        echo "[dr-done] All tasks complete. Loop stopped." >&2
        ;;
esac
