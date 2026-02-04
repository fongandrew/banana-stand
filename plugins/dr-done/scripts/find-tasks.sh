#!/bin/bash
# find-tasks.sh - Find tasks by type
# Part of dr-done v2 plugin
#
# Usage: find-tasks.sh <type> [--limit N]
#   type: pending, review, done, stuck, all
#   --limit N: Only show first N results (default: unlimited)
#
# Output: List of task file paths, one per line
#         Outputs "(none)" if no tasks found

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

init_dr_done 2>/dev/null || true

TYPE="${1:-pending}"
LIMIT=0

# Parse arguments
shift || true
while [[ $# -gt 0 ]]; do
    case "$1" in
        --limit)
            LIMIT="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Find tasks based on type
case "$TYPE" in
    pending)
        TASKS=$(find_pending_tasks)
        ;;
    review)
        TASKS=$(find_review_tasks)
        ;;
    done)
        TASKS=$(find_done_tasks)
        ;;
    stuck)
        TASKS=$(find_stuck_tasks)
        ;;
    all)
        if [[ -d "$TASKS_DIR" ]]; then
            TASKS=$(find "$TASKS_DIR" -maxdepth 1 -name "*.md" 2>/dev/null | sort)
        else
            TASKS=""
        fi
        ;;
    *)
        echo "Unknown type: $TYPE" >&2
        echo "Valid types: pending, review, done, stuck, all" >&2
        exit 1
        ;;
esac

# Apply limit if specified
if [[ -n "$TASKS" ]]; then
    if [[ "$LIMIT" -gt 0 ]]; then
        echo "$TASKS" | head -n "$LIMIT"
    else
        echo "$TASKS"
    fi
else
    echo "(none)"
fi
