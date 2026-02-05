#!/bin/bash
# set-focus.sh - Set focus to a specific task file
#
# Usage: set-focus.sh <task-file>
#
# The task-file should be relative to the repo root (e.g., .dr-done/tasks/12345-my-task.md)
#
# Exit codes: 0 = success, 1 = error

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

init_dr_done

TASK_FILE="$1"

if [[ -z "$TASK_FILE" ]]; then
    echo "Error: task-file required" >&2
    exit 1
fi

# Verify the file exists
if [[ ! -f "$REPO_ROOT/$TASK_FILE" ]]; then
    echo "Error: Task file not found: $TASK_FILE" >&2
    exit 1
fi

set_focus "$TASK_FILE"
echo "Focus set to: $TASK_FILE"
