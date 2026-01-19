#!/bin/bash
# PreToolUse hook for faq-check plugin
# Wraps Bash commands with FAQ checker for output matching

set -e

# Debug logging
LOG_FILE="/tmp/claude/faq-check-debug.log"
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

log "=== pre-tool-use.sh started ==="

# Get plugin directory (where this script lives)
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WRAPPER_SCRIPT="$PLUGIN_DIR/scripts/faq-wrapper.sh"

# Read tool input from stdin
INPUT=$(cat)
log "INPUT: $INPUT"

# Check if this is a Bash tool call - exit early if not
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
log "TOOL_NAME: $TOOL_NAME"
if [[ "$TOOL_NAME" != "Bash" ]]; then
    log "Not a Bash tool, exiting"
    exit 0
fi

# Parse the command from JSON input
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
log "COMMAND: $COMMAND"

# If no command, pass through unchanged
if [[ -z "$COMMAND" ]]; then
    log "No command found, exiting"
    exit 0
fi

# Check for opt-out via FAQ_CHECK=0 prefix
if [[ "$COMMAND" =~ ^FAQ_CHECK=0[[:space:]](.*)$ ]]; then
    # Strip the prefix and pass through the rest unchanged
    STRIPPED_COMMAND="${BASH_REMATCH[1]}"
    log "FAQ_CHECK=0 detected, stripped command: $STRIPPED_COMMAND"
    # Output JSON with stripped command (no wrapping) using correct hook output format
    jq -n --arg cmd "$STRIPPED_COMMAND" '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "allow",
        "updatedInput": {
          "command": $cmd
        }
      }
    }'
    exit 0
fi

# Encode the command in base64 to avoid shell escaping issues
ENCODED_COMMAND=$(echo -n "$COMMAND" | base64)
log "ENCODED_COMMAND: $ENCODED_COMMAND"

# Wrap the command with the FAQ wrapper using base64 flag
WRAPPED_COMMAND="$WRAPPER_SCRIPT --base64 $ENCODED_COMMAND"
log "WRAPPED_COMMAND: $WRAPPED_COMMAND"

# Output JSON with the wrapped command using correct hook output format
OUTPUT=$(jq -n --arg cmd "$WRAPPED_COMMAND" '{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "updatedInput": {
      "command": $cmd
    }
  }
}')
log "OUTPUT: $OUTPUT"
echo "$OUTPUT"
