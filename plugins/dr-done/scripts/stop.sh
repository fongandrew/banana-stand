#!/bin/bash
# stop.sh - Stop the dr-done loop
#
# Usage: stop.sh <session_id>
# Exit codes:
#   0 - Success (stopped)
#   1 - Error
#   2 - No active looper
#   3 - Different session is active (outputs that session ID)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

SESSION_ID="${1:-}"

if [[ -z "$SESSION_ID" ]]; then
    echo "Error: Session ID required" >&2
    exit 1
fi

init_dr_done

# Check if state file exists
if [[ ! -f "$STATE_FILE" ]]; then
    echo "no-looper"
    exit 2
fi

# Read current looper
CURRENT_LOOPER=$(jq -r '.looper // empty' "$STATE_FILE" 2>/dev/null || echo "")

if [[ -z "$CURRENT_LOOPER" || "$CURRENT_LOOPER" == "null" ]]; then
    echo "no-looper"
    exit 2
fi

# Check if this session is the looper
if [[ "$CURRENT_LOOPER" != "$SESSION_ID" ]]; then
    echo "other-session:$CURRENT_LOOPER"
    exit 3
fi

# This session is the looper - stop it
CURRENT_ITERATION=$(jq -r '.iteration // 0' "$STATE_FILE" 2>/dev/null || echo "0")

# Update state to clear looper
echo "{\"looper\": null, \"iteration\": $CURRENT_ITERATION}" > "$STATE_FILE"

echo "stopped"
exit 0
