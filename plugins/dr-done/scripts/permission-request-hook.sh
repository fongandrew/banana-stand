#!/bin/bash
# permission-request-hook.sh - Auto-deny permission requests in autonomous mode
# Part of dr-done v2 plugin
#
# When the session is the active looper, permission requests are denied
# to keep the autonomous loop running without human intervention.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Read input from stdin
INPUT=$(cat)

init_dr_done

# No state file = not in autonomous mode, allow permission request
if [[ ! -f "$STATE_FILE" ]]; then
    exit 0
fi

# Get session ID from input
SESSION_ID=$(get_session_id_from_input "$INPUT")
if [[ -z "$SESSION_ID" ]]; then
    # No session ID means we can't check looper status, allow request
    exit 0
fi

# Not the looper = allow permission request
if ! is_looper "$SESSION_ID"; then
    exit 0
fi

# We are the looper - deny the permission request
cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PermissionRequest",
    "decision": {
      "behavior": "deny",
      "message": "This dr-done loop is running autonomously and cannot request permissions.\n\nThe command you're trying to run requires approval. Please:\n1. Try running the command in a way that doesn't require permission (e.g., sandboxed bash)\n2. Check .claude/settings.json or .claude/settings.local.json for allowlisted paths\n3. If this command is truly required and cannot be sandboxed, mark this task as .stuck.md with an explanation"
    }
  }
}
EOF
