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

# Check for tasks needing review
review_tasks=$(find_review_tasks)
if [[ -n "$review_tasks" ]]; then
    next_review=$(echo "$review_tasks" | head -1)
    user_instructions=$(get_user_review_instructions)

    # Build the review task for the subagent
    review_task="Review the completed task at: $next_review"
    if [[ -n "$user_instructions" ]]; then
        review_task="$review_task

$user_instructions"
    fi

    output_block "Task ready for review. Use the Task tool to spawn the dr-done:reviewer subagent with this prompt:

$review_task"
    exit 0
fi

# Check for pending tasks
pending_tasks=$(find_pending_tasks)
if [[ -n "$pending_tasks" ]]; then
    next_task=$(echo "$pending_tasks" | head -1)

    if [[ "$CONFIG_REVIEW" == "true" ]]; then
        done_extension=".review.md"
        review_instruction="- If complete, spawn a reviewer subagent with the review prompt"
    else
        done_extension=".done.md"
        review_instruction=""
    fi

    if [[ "$CONFIG_GIT_COMMIT" == "true" ]]; then
        commit_instruction="- Commit your changes with a descriptive message"
    else
        commit_instruction=""
    fi

    loop_prompt=$(build_loop_prompt "$next_task" "$done_extension" "$commit_instruction" "$review_instruction")

    output_block "$loop_prompt"
    exit 0
fi

# Check for stuck tasks
stuck_tasks=$(find_stuck_tasks)
if [[ -n "$stuck_tasks" ]]; then
    stuck_count=$(echo "$stuck_tasks" | wc -l | tr -d ' ')
    clear_looper
    echo "[dr-done] $stuck_count stuck task(s) need attention. Use /dr-done:unstick to retry." >&2
    exit 0
fi

# No pending tasks, no review tasks, no stuck tasks = queue complete
clear_looper
echo "[dr-done] All tasks complete. Loop stopped." >&2
exit 0
