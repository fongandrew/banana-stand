#!/bin/bash
# user-prompt-submit-hook.sh - Remind agent of stuck tasks

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Read input from stdin
INPUT=$(cat)

init_dr_done

# Read config to check if stuck task reminders are enabled
read_config

# Exit early if stuck task reminders are disabled
if [[ "$CONFIG_STUCK_REMINDER" == "false" ]]; then
    exit 0
fi

# Check for stuck tasks (always, regardless of looper session)
stuck_tasks=$(find_stuck_tasks)
if [[ -n "$stuck_tasks" ]]; then
    stuck_count=$(echo "$stuck_tasks" | wc -l | tr -d ' ')
    stuck_files=$(echo "$stuck_tasks" | xargs -I {} basename {} | tr '\n' ', ' | sed 's/,$//')

    echo "[dr-done] $stuck_count stuck task(s): $stuck_files"
    echo "If user input resolves, edit task and mv from .stuck.md to .md. Do not do task unless user tells you to."
fi

exit 0
