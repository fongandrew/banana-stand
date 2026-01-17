#!/bin/bash
# Stop hook for dr-done
# Manages the iteration loop and decides whether to continue processing tasks

set -e

# Get repository root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [[ -z "$REPO_ROOT" ]]; then
    exit 0
fi

STATE_FILE="$REPO_ROOT/.claude/dr-done.local.yaml"

# If state file doesn't exist, dr-done is not active - allow stop
if [[ ! -f "$STATE_FILE" ]]; then
    exit 0
fi

# Read YAML values (simple parsing for bash 3.2+ compatibility)
MAX=$(grep '^max:' "$STATE_FILE" | sed 's/max:[[:space:]]*//')
ITERATION=$(grep '^iteration:' "$STATE_FILE" | sed 's/iteration:[[:space:]]*//')
WORKSTREAM=$(grep '^workstream:' "$STATE_FILE" | sed 's/workstream:[[:space:]]*//')

# Increment iteration
NEW_ITERATION=$((ITERATION + 1))

# Update state file with new iteration
cat > "$STATE_FILE" << EOF
max: $MAX
iteration: $NEW_ITERATION
workstream: $WORKSTREAM
EOF

# Check if we've exceeded max iterations
if [[ $NEW_ITERATION -gt $MAX ]]; then
    rm -f "$STATE_FILE"
    echo "dr-done: Maximum iterations ($MAX) reached. Stopping."
    exit 0
fi

# Check if all tasks are complete
WORKSTREAM_DIR="$REPO_ROOT/.dr-done/$WORKSTREAM"

if [[ ! -d "$WORKSTREAM_DIR" ]]; then
    rm -f "$STATE_FILE"
    exit 0
fi

# Find pending tasks (not .done.md or .stuck.md)
PENDING_TASKS=$(find "$WORKSTREAM_DIR" -maxdepth 1 -name "*.md" \
    ! -name "*.done.md" \
    ! -name "*.stuck.md" \
    2>/dev/null | head -1)

if [[ -z "$PENDING_TASKS" ]]; then
    # All tasks complete
    rm -f "$STATE_FILE"
    echo "dr-done: All tasks in workstream '$WORKSTREAM' are complete. Stopping."
    exit 0
fi

# Tasks remaining - block and continue
cat << 'EOF'
{
  "decision": "block",
  "reason": "Tasks remaining in workstream. Spawn a sub-agent to follow the instructions in .dr-done/prompt.md"
}
EOF
