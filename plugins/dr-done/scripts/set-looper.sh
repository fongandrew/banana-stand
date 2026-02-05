#!/bin/bash
# set-looper.sh - Set the current session as the looper
#
# Usage: set-looper.sh <session_id>
#
# Exit codes: 0 = success, 1 = error

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

init_dr_done

SESSION_ID="$1"

if [[ -z "$SESSION_ID" ]]; then
    echo "Error: session_id required" >&2
    exit 1
fi

set_looper "$SESSION_ID"
echo "Looper set to: $SESSION_ID"
