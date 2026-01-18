#!/bin/bash
# PermissionRequest hook for dr-done
# Auto-denies Bash permission requests when running in autonomous dr-done mode

# Debug logging
DEBUG_LOG="/tmp/claude/dr-done-permission-hook.log"
mkdir -p "$(dirname "$DEBUG_LOG")"

echo "=== PermissionRequest hook triggered ===" >> "$DEBUG_LOG"
echo "Timestamp: $(date)" >> "$DEBUG_LOG"
echo "CLAUDE_PROJECT_DIR: $CLAUDE_PROJECT_DIR" >> "$DEBUG_LOG"
echo "CLAUDE_PLUGIN_ROOT: $CLAUDE_PLUGIN_ROOT" >> "$DEBUG_LOG"
echo "PWD: $PWD" >> "$DEBUG_LOG"

DR_DONE_CONFIG="$CLAUDE_PROJECT_DIR/.claude/dr-done.local.yaml"
echo "Looking for config at: $DR_DONE_CONFIG" >> "$DEBUG_LOG"

# If dr-done config doesn't exist, this is not an autonomous loop - no-op
if [[ ! -f "$DR_DONE_CONFIG" ]]; then
    echo "Config not found - exiting with no-op (exit 0)" >> "$DEBUG_LOG"
    exit 0
fi

echo "Config found - will auto-deny permission request" >> "$DEBUG_LOG"

# Auto-deny the permission request in autonomous mode
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
