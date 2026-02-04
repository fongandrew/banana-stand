#!/bin/bash
# generate-loop-prompt.sh - Generate the main loop prompt for the next task
# Part of dr-done v2 plugin
#
# This outputs the exact same prompt used by stop-hook.sh and session-start-hook.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/template.sh"

init_dr_done

# Read config
read_config

# Check for tasks needing review first
review_tasks=$(find_review_tasks)
if [[ -n "$review_tasks" ]]; then
    next_review=$(echo "$review_tasks" | head -1)
    user_instructions=$(get_user_review_instructions)

    echo "Task ready for review. Use the Task tool to spawn the dr-done:reviewer subagent with this prompt:"
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

    build_loop_prompt "$next_task" "$done_extension" "$commit_instruction" "$review_instruction"
    exit 0
fi

# Queue empty
echo "All tasks complete. Nothing to do."
exit 0
