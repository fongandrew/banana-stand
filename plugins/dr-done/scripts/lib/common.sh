#!/bin/bash
# common.sh - Shared functions for dr-done v2 plugin
# Part of dr-done v2 plugin

# Get repository root
get_repo_root() {
    git rev-parse --show-toplevel 2>/dev/null
}

# Initialize common variables
# Call this at the start of each script that sources common.sh
init_dr_done() {
    REPO_ROOT=$(get_repo_root)
    if [[ -z "$REPO_ROOT" ]]; then
        echo "Error: Not in a git repository" >&2
        return 1
    fi

    DR_DONE_DIR="$REPO_ROOT/.dr-done"
    TASKS_DIR="$DR_DONE_DIR/tasks"
    STATE_FILE="$DR_DONE_DIR/state.json"
    CONFIG_FILE="$DR_DONE_DIR/config.json"
}

# Read configuration with defaults
# Returns: gitCommit, maxIterations, review as global variables
read_config() {
    # Defaults
    CONFIG_GIT_COMMIT=true
    CONFIG_MAX_ITERATIONS=50
    CONFIG_REVIEW=true

    if [[ -f "$CONFIG_FILE" ]]; then
        # Note: Don't use jq's // operator for booleans - it treats false as falsy
        local git_commit=$(jq -r '.gitCommit | if . == null then "true" else . end' "$CONFIG_FILE")
        local max_iter=$(jq -r '.maxIterations // 50' "$CONFIG_FILE")
        local review=$(jq -r '.review | if . == null then "true" else . end' "$CONFIG_FILE")

        if [[ "$git_commit" == "false" ]]; then
            CONFIG_GIT_COMMIT=false
        fi
        if [[ "$max_iter" =~ ^[0-9]+$ ]]; then
            CONFIG_MAX_ITERATIONS=$max_iter
        fi
        if [[ "$review" == "false" ]]; then
            CONFIG_REVIEW=false
        fi
    fi
}

# Find pending tasks (.md but not .review.md, .done.md, or .stuck.md)
find_pending_tasks() {
    if [[ ! -d "$TASKS_DIR" ]]; then
        return
    fi
    find "$TASKS_DIR" -maxdepth 1 -name "*.md" \
        ! -name "*.review.md" \
        ! -name "*.done.md" \
        ! -name "*.stuck.md" \
        2>/dev/null | sort
}

# Find review tasks (.review.md files)
find_review_tasks() {
    if [[ ! -d "$TASKS_DIR" ]]; then
        return
    fi
    find "$TASKS_DIR" -maxdepth 1 -name "*.review.md" 2>/dev/null | sort
}

# Find done tasks (.done.md files)
find_done_tasks() {
    if [[ ! -d "$TASKS_DIR" ]]; then
        return
    fi
    find "$TASKS_DIR" -maxdepth 1 -name "*.done.md" 2>/dev/null | sort
}

# Find stuck tasks (.stuck.md files)
find_stuck_tasks() {
    if [[ ! -d "$TASKS_DIR" ]]; then
        return
    fi
    find "$TASKS_DIR" -maxdepth 1 -name "*.stuck.md" 2>/dev/null | sort
}

# Check for uncommitted changes (excluding .dr-done/ directory)
has_uncommitted_changes() {
    git status --porcelain 2>/dev/null | grep -v "^.. .dr-done/" | grep -q .
}

# Check if session is the current looper
is_looper() {
    local session_id="$1"
    if [[ ! -f "$STATE_FILE" ]]; then
        return 1
    fi
    local looper=$(jq -r '.looper // empty' "$STATE_FILE")
    [[ "$looper" == "$session_id" ]]
}

# Set looper to a session ID
set_looper() {
    local session_id="$1"
    cat > "$STATE_FILE" << EOF
{"looper": "$session_id", "iteration": 0}
EOF
}

# Clear looper (set to null)
clear_looper() {
    if [[ -f "$STATE_FILE" ]]; then
        local iteration=$(jq -r '.iteration // 0' "$STATE_FILE")
        cat > "$STATE_FILE" << EOF
{"looper": null, "iteration": $iteration}
EOF
    fi
}

# Increment iteration counter
increment_iteration() {
    if [[ -f "$STATE_FILE" ]]; then
        local looper=$(jq -r '.looper' "$STATE_FILE")
        local iteration=$(jq -r '.iteration // 0' "$STATE_FILE")
        iteration=$((iteration + 1))
        # Quote looper if it's not null
        if [[ "$looper" == "null" ]]; then
            cat > "$STATE_FILE" << EOF
{"looper": null, "iteration": $iteration}
EOF
        else
            cat > "$STATE_FILE" << EOF
{"looper": "$looper", "iteration": $iteration}
EOF
        fi
        echo "$iteration"
    else
        echo "0"
    fi
}

# Set focus to a specific task file (relative path from repo root)
set_focus() {
    local task_file="$1"
    if [[ -f "$STATE_FILE" ]]; then
        local looper=$(jq -r '.looper' "$STATE_FILE")
        local iteration=$(jq -r '.iteration // 0' "$STATE_FILE")
        if [[ "$looper" == "null" ]]; then
            cat > "$STATE_FILE" << EOF
{"looper": null, "iteration": $iteration, "focus": "$task_file"}
EOF
        else
            cat > "$STATE_FILE" << EOF
{"looper": "$looper", "iteration": $iteration, "focus": "$task_file"}
EOF
        fi
    else
        cat > "$STATE_FILE" << EOF
{"looper": null, "iteration": 0, "focus": "$task_file"}
EOF
    fi
}

# Get current focus (returns empty if none)
get_focus() {
    if [[ -f "$STATE_FILE" ]]; then
        jq -r '.focus // empty' "$STATE_FILE"
    fi
}

# Clear focus
clear_focus() {
    if [[ -f "$STATE_FILE" ]]; then
        local looper=$(jq -r '.looper' "$STATE_FILE")
        local iteration=$(jq -r '.iteration // 0' "$STATE_FILE")
        if [[ "$looper" == "null" ]]; then
            cat > "$STATE_FILE" << EOF
{"looper": null, "iteration": $iteration}
EOF
        else
            cat > "$STATE_FILE" << EOF
{"looper": "$looper", "iteration": $iteration}
EOF
        fi
    fi
}

# Extract session_id from hook input JSON
get_session_id_from_input() {
    local input="$1"
    echo "$input" | jq -r '.session_id // empty'
}

# Output JSON for hook responses
output_block() {
    local reason="$1"
    # Escape the reason for JSON
    local escaped_reason=$(echo "$reason" | jq -Rs '.')
    cat << EOF
{"decision": "block", "reason": $escaped_reason}
EOF
}
