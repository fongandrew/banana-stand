#!/bin/bash
# template.sh - Template functions for dr-done plugin

# Get the next task info
# Sets NEXT_TASK_TYPE (review|pending|stuck|complete) and NEXT_TASK_FILE
get_next_task() {
    NEXT_TASK_TYPE=""
    NEXT_TASK_FILE=""

    # Check for focused task first
    local focus=$(get_focus)
    if [[ -n "$focus" ]]; then
        local focus_path="$REPO_ROOT/$focus"
        if [[ -f "$focus_path" ]]; then
            NEXT_TASK_FILE="$focus_path"
            # Determine type from extension
            if [[ "$focus" == *.review.md ]]; then
                NEXT_TASK_TYPE="review"
            elif [[ "$focus" == *.stuck.md ]]; then
                NEXT_TASK_TYPE="stuck"
            elif [[ "$focus" == *.done.md ]]; then
                # Focused task is done, clear focus and continue
                clear_focus
            else
                NEXT_TASK_TYPE="pending"
            fi
            if [[ -n "$NEXT_TASK_TYPE" ]]; then
                return 0
            fi
        else
            # Focus file doesn't exist, clear it
            clear_focus
        fi
    fi

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

- If you have previously read this file, re-read it. It may have changed.
- If the task is complicated, use task tools to track subtasks.
- Check TaskList tool for existing open subtasks.
- Do a meaningful amount of work.
- Append work summary to the file, then rename extension:
    - \`$done_extension\` = complete
    - \`.stuck.md\` = need help
    - \`.md\` = more work needed
$commit_instruction
$review_instruction
- Then wait for next task
EOF
}
