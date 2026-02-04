#!/bin/bash
# read-state.sh - Read dr-done state with fallback
# Part of dr-done v2 plugin
#
# Usage: read-state.sh
# Output: JSON state object (or default if no state file)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

init_dr_done 2>/dev/null || true

if [[ -f "$STATE_FILE" ]]; then
    cat "$STATE_FILE"
else
    echo '{"looper": null, "iteration": 0}'
fi
