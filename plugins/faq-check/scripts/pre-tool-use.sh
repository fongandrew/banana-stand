#!/bin/bash
# PreToolUse hook for faq-check plugin
# Wraps Bash commands with FAQ checker for output matching

set -e

# Get plugin directory (where this script lives)
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WRAPPER_SCRIPT="$PLUGIN_DIR/scripts/faq-wrapper.sh"

# Read tool input from stdin
INPUT=$(cat)

# Parse the command from JSON input
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# If no command, pass through unchanged
if [[ -z "$COMMAND" ]]; then
    exit 0
fi

# Check for opt-out via FAQ_CHECK=0 prefix
if [[ "$COMMAND" =~ ^FAQ_CHECK=0[[:space:]](.*)$ ]]; then
    # Strip the prefix and pass through the rest unchanged
    STRIPPED_COMMAND="${BASH_REMATCH[1]}"
    # Output JSON with stripped command (no wrapping)
    jq -n --arg cmd "$STRIPPED_COMMAND" '{"command": $cmd}'
    exit 0
fi

# Escape the command for passing as a single-quoted argument
# Single quotes need special handling: replace ' with '\''
ESCAPED_COMMAND="${COMMAND//\'/\'\\\'\'}"

# Wrap the command with the FAQ wrapper
WRAPPED_COMMAND="$WRAPPER_SCRIPT '$ESCAPED_COMMAND'"

# Output JSON with the wrapped command
jq -n --arg cmd "$WRAPPED_COMMAND" '{"command": $cmd}'
