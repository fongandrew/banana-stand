#!/bin/bash
# template.sh - Template variable substitution for dr-done v2 plugin
# Part of dr-done v2 plugin

# Get user review instructions from REVIEW.md if it exists
get_user_review_instructions() {
    local user_review_file="$DR_DONE_DIR/REVIEW.md"
    if [[ -f "$user_review_file" ]]; then
        echo ""
        echo "## Project-Specific Guidelines"
        echo ""
        cat "$user_review_file"
    fi
}

# Build the loop prompt for the main agent
build_loop_prompt() {
    local task_file="$1"
    local done_extension="$2"
    local commit_instruction="$3"
    local review_instruction="$4"

    cat << EOF
You are in a task completion loop.

Current: $task_file

- Re-read file if needed.
- Check TaskList tool for existing open subtasks.
- Do a meaningful amount of work.
$commit_instruction
- Append work summary to the file, then rename:
    - \`$done_extension\` = complete
    - \`.stuck.md\` = need help
    - \`.md\` = more work needed
$review_instruction
- Call \`stop\`
EOF
}
