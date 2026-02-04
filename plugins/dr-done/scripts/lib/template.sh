#!/bin/bash
# template.sh - Template functions for dr-done v2 plugin
# Part of dr-done v2 plugin

# Get the next task info
# Sets NEXT_TASK_TYPE (review|pending|stuck|complete) and NEXT_TASK_FILE
get_next_task() {
    NEXT_TASK_TYPE=""
    NEXT_TASK_FILE=""

    # Check for tasks needing review first
    local review_tasks=$(find_review_tasks)
    if [[ -n "$review_tasks" ]]; then
        NEXT_TASK_TYPE="review"
        NEXT_TASK_FILE=$(echo "$review_tasks" | head -1)
        return 0
    fi

    # Check for pending tasks
    local pending_tasks=$(find_pending_tasks)
    if [[ -n "$pending_tasks" ]]; then
        NEXT_TASK_TYPE="pending"
        NEXT_TASK_FILE=$(echo "$pending_tasks" | head -1)
        return 0
    fi

    # Check for stuck tasks
    local stuck_tasks=$(find_stuck_tasks)
    if [[ -n "$stuck_tasks" ]]; then
        NEXT_TASK_TYPE="stuck"
        NEXT_TASK_FILE=$(echo "$stuck_tasks" | head -1)
        return 0
    fi

    # Queue complete
    NEXT_TASK_TYPE="complete"
    return 0
}

# Build the review prompt
build_review_prompt() {
    local task_file="$1"
    echo "Use the Task tool to spawn the dr-done:reviewer subagent and review: $task_file"
}

# Build the pending task prompt
# Requires read_config to have been called first
build_pending_prompt() {
    local task_file="$1"

    local done_extension
    local review_instruction
    local commit_instruction

    if [[ "$CONFIG_REVIEW" == "true" ]]; then
        done_extension=".review.md"
        review_instruction="- If complete, spawn the dr-done:reviewer subagent and have it review the renamed file."
    else
        done_extension=".done.md"
        review_instruction=""
    fi

    if [[ "$CONFIG_GIT_COMMIT" == "true" ]]; then
        commit_instruction="- Commit your changes with a descriptive message"
    else
        commit_instruction=""
    fi

    cat << EOF
Work on this task: $task_file

- Re-read file if needed.
- Check TaskList tool for existing open subtasks.
- Do a meaningful amount of work.
- Append work summary to the file, then rename:
    - \`$done_extension\` = complete
    - \`.stuck.md\` = need help
    - \`.md\` = more work needed
$commit_instruction
$review_instruction
EOF
}
