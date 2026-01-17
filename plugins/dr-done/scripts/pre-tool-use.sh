#!/bin/bash
# PreToolUse hook for dr-done
# Denies permission requests when running in autonomous dr-done mode

DR_DONE_CONFIG="$CLAUDE_PROJECT_DIR/.claude/dr-done.local.yaml"

# If dr-done config doesn't exist, this is not an autonomous loop - no-op
if [[ ! -f "$DR_DONE_CONFIG" ]]; then
    exit 0
fi

# Read tool input from stdin
INPUT=$(cat)

# Parse tool name and check for dangerouslyDisableSandbox
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
DISABLE_SANDBOX=$(echo "$INPUT" | jq -r '.tool_input.dangerouslyDisableSandbox // false')

# Check if this is a Bash tool requesting unsandboxed execution
if [[ "$TOOL_NAME" == "Bash" ]] && [[ "$DISABLE_SANDBOX" == "true" ]]; then
    cat << 'EOF'
{
  "decision": "block",
  "reason": "This dr-done loop is running autonomously and cannot request permissions.\n\nThe command you're trying to run requires unsandboxed bash. Please:\n1. Try running the command WITHOUT dangerouslyDisableSandbox - sandboxed bash may work\n2. If sandboxed bash fails, check .claude/settings.json or .claude/settings.local.json for allowlisted paths\n3. If this command is truly required and cannot be sandboxed, mark this task as .stuck.md with an explanation"
}
EOF
    exit 0
fi

# No issues detected - allow normal flow to proceed
exit 0
