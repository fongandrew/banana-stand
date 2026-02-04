#!/bin/bash
# user-prompt-submit-hook.sh - Remind agent of stuck tasks
# Part of dr-done v2 plugin

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

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

# Not the looper = no reminders needed
if ! is_looper "$SESSION_ID"; then
    exit 0
fi

# Check for stuck tasks
stuck_tasks=$(find_stuck_tasks)
if [[ -n "$stuck_tasks" ]]; then
    stuck_count=$(echo "$stuck_tasks" | wc -l | tr -d ' ')
    stuck_files=$(echo "$stuck_tasks" | xargs -I {} basename {} | tr '\n' ', ' | sed 's/,$//')

    echo "[dr-done] There are $stuck_count stuck task(s): $stuck_files"
    echo "If your input helps resolve these, rename them from .stuck.md to .md"
fi

exit 0
