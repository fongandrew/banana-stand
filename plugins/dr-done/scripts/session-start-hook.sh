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

# Read config
read_config

# Check for tasks needing review
review_tasks=$(find_review_tasks)
if [[ -n "$review_tasks" ]]; then
    next_review=$(echo "$review_tasks" | head -1)
    user_instructions=$(get_user_review_instructions)

    echo "[dr-done] Session resumed. Task ready for review."
    echo ""
    echo "Use the Task tool to spawn the dr-done:reviewer subagent with this prompt:"
    echo ""
    echo "Review the completed task at: $next_review"
    if [[ -n "$user_instructions" ]]; then
        echo ""
        echo "$user_instructions"
    fi
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

    echo "[dr-done] Session resumed. Continue with the loop:"
    echo ""
    echo "$loop_prompt"
    exit 0
fi

# Queue empty
echo "[dr-done] Session resumed. All tasks complete."
exit 0
