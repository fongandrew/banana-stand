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

# Debug logging
LOG_FILE="$DR_DONE_DIR/stop-hook.log"
{
    echo "=== Stop hook called at $(date) ==="
    echo "SESSION_ID from input: $(echo "$INPUT" | jq -r '.session_id // "none"')"
} >> "$LOG_FILE"

# No state file = not active, allow stop
if [[ ! -f "$STATE_FILE" ]]; then
    echo "No state file, allowing stop" >> "$LOG_FILE"
    exit 0
fi

# Get session ID from input
SESSION_ID=$(get_session_id_from_input "$INPUT")
if [[ -z "$SESSION_ID" ]]; then
    # No session ID means we can't check looper status, allow stop
    echo "No session ID, allowing stop" >> "$LOG_FILE"
    exit 0
fi

# Not the looper = allow stop
if ! is_looper "$SESSION_ID"; then
    echo "Not the looper, allowing stop" >> "$LOG_FILE"
    exit 0
fi

echo "We are the looper" >> "$LOG_FILE"

# We are the looper - increment iteration
new_iteration=$(increment_iteration)
echo "Iteration: $new_iteration" >> "$LOG_FILE"

# Read config
read_config
echo "Config: gitCommit=$CONFIG_GIT_COMMIT, maxIterations=$CONFIG_MAX_ITERATIONS, review=$CONFIG_REVIEW" >> "$LOG_FILE"

# Max iterations exceeded - clear looper and allow stop
if [[ $new_iteration -gt $CONFIG_MAX_ITERATIONS ]]; then
    echo "Max iterations exceeded, clearing looper" >> "$LOG_FILE"
    clear_looper
    echo "[dr-done] Max iterations ($CONFIG_MAX_ITERATIONS) reached. Loop stopped." >&2
    exit 0
fi

# Check for uncommitted changes (if gitCommit enabled)
if [[ "$CONFIG_GIT_COMMIT" == "true" ]] && has_uncommitted_changes; then
    echo "Uncommitted changes detected, blocking" >> "$LOG_FILE"
    output_block "You have uncommitted changes. Please commit your work before continuing."
    exit 0
fi

# Get next task and handle accordingly
get_next_task
echo "Next task type: $NEXT_TASK_TYPE, file: $NEXT_TASK_FILE" >> "$LOG_FILE"

case "$NEXT_TASK_TYPE" in
    review)
        echo "Blocking for review task" >> "$LOG_FILE"
        output_block "Task ready for review. $(build_review_prompt "$NEXT_TASK_FILE")"
        ;;
    pending)
        echo "Blocking for pending task" >> "$LOG_FILE"
        output_block "$(build_pending_prompt "$NEXT_TASK_FILE")"
        ;;
    stuck)
        stuck_count=$(find_stuck_tasks | wc -l | tr -d ' ')
        echo "Stuck tasks detected ($stuck_count), clearing looper" >> "$LOG_FILE"
        clear_looper
        echo "[dr-done] $stuck_count stuck task(s) need attention. Use /dr-done:unstick to retry." >&2
        ;;
    complete)
        echo "All tasks complete, clearing looper" >> "$LOG_FILE"
        clear_looper
        echo "[dr-done] All tasks complete. Loop stopped." >&2
        ;;
esac
