#!/bin/bash
# SubagentStop hook for dr-done
# Enforces that all work is committed before the sub-agent can stop

# Check for uncommitted changes
if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
    cat << 'EOF'
{
  "decision": "block",
  "reason": "You have uncommitted changes. Please commit your work before stopping."
}
EOF
    exit 0
fi

# No uncommitted changes - allow stop
exit 0
