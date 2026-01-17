#!/bin/bash
# SubagentStop hook for dr-done
# Enforces that all work is committed before the sub-agent can stop

DR_DONE_CONFIG=".claude/dr-done.local.yaml"

# Only enforce uncommitted changes rule if dr-done config exists
if [[ ! -f "$DR_DONE_CONFIG" ]]; then
    exit 0
fi

# Read the active workstream from config
WORKSTREAM=$(grep '^workstream:' "$DR_DONE_CONFIG" | sed 's/workstream: *//')

if [[ -z "$WORKSTREAM" ]]; then
    # No workstream configured - allow stop
    exit 0
fi

# Get all uncommitted changes
CHANGES=$(git status --porcelain 2>/dev/null)

if [[ -z "$CHANGES" ]]; then
    # No uncommitted changes - allow stop
    exit 0
fi

# Filter changes to only include:
# 1. Files outside .dr-done/
# 2. Files in the active workstream directory (.dr-done/{workstream}/)
# Ignore changes in other .dr-done/ subdirectories

RELEVANT_CHANGES=$(echo "$CHANGES" | while read -r line; do
    # Extract the file path (skip the status prefix)
    filepath="${line:3}"

    # Handle renamed files (format: "R  old -> new")
    if [[ "$filepath" == *" -> "* ]]; then
        filepath="${filepath##* -> }"
    fi

    # Check if file is in .dr-done/
    if [[ "$filepath" == .dr-done/* ]]; then
        # Check if it's in the active workstream directory
        if [[ "$filepath" == .dr-done/${WORKSTREAM}/* ]]; then
            echo "$line"
        fi
        # Else: it's in another .dr-done/ subdirectory - ignore it
    else
        # File is outside .dr-done/ - include it
        echo "$line"
    fi
done)

if [[ -n "$RELEVANT_CHANGES" ]]; then
    cat << 'EOF'
{
  "decision": "block",
  "reason": "You have uncommitted changes. Please commit your work before stopping."
}
EOF
    exit 0
fi

# No relevant uncommitted changes - allow stop
exit 0
