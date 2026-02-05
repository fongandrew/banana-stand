#!/bin/bash
# permission-request-hook.sh - Auto-deny permission requests in autonomous mode
#
# When the session is the active looper, permission requests are denied
# to keep the autonomous loop running without human intervention.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Read input from stdin
INPUT=$(cat)

init_dr_done

# Get session ID from input
SESSION_ID=$(get_session_id_from_input "$INPUT")

# No state file = not in autonomous mode, allow permission request
if [[ ! -f "$STATE_FILE" ]]; then
    log_debug "$SESSION_ID" "permission: no state file, allowing"
    exit 0
fi

if [[ -z "$SESSION_ID" ]]; then
    log_debug "$SESSION_ID" "permission: no session ID, allowing"
    exit 0
fi

# Not the looper = allow permission request
if ! is_looper "$SESSION_ID"; then
    log_debug "$SESSION_ID" "permission: not looper, allowing"
    exit 0
fi

# We are the looper - deny the permission request
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
log_debug "$SESSION_ID" "permission: denied $TOOL_NAME (looper mode)"

# Special case for web tools - simpler message without alternatives
# to avoid using sandboxed curl and triggering permission request
if [[ "$TOOL_NAME" == "WebFetch" || "$TOOL_NAME" == "WebSearch" ]]; then
    cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PermissionRequest",
    "decision": {
      "behavior": "deny",
      "message": "This dr-done loop is running autonomously and cannot access the web.\n\nTry to complete the task without accessing this domain, or mark the task as .stuck.md if web access is required."
    }
  }
}
EOF
else
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
fi
