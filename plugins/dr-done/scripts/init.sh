#!/bin/bash
# init.sh - Initialize dr-done directory structure
#
# Usage: init.sh [--with-config]
#   --with-config: Also create config.json with defaults (if it doesn't exist)
#
# This script is idempotent - safe to call multiple times.
# Exit codes: 0 = success, 1 = error

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

init_dr_done

# Parse arguments
WITH_CONFIG=false
for arg in "$@"; do
    case "$arg" in
        --with-config) WITH_CONFIG=true ;;
    esac
done

# Create directories
mkdir -p "$TASKS_DIR"

# Create .gitignore if needed
GITIGNORE="$DR_DONE_DIR/.gitignore"
if [[ ! -f "$GITIGNORE" ]]; then
    printf "tasks/\nstate.json\n" > "$GITIGNORE"
else
    grep -q "^tasks/$" "$GITIGNORE" 2>/dev/null || echo "tasks/" >> "$GITIGNORE"
    grep -q "^state\.json$" "$GITIGNORE" 2>/dev/null || echo "state.json" >> "$GITIGNORE"
fi

# Create config.json if requested and doesn't exist
if [[ "$WITH_CONFIG" == "true" && ! -f "$CONFIG_FILE" ]]; then
    cat > "$CONFIG_FILE" << 'EOF'
{
  "gitCommit": true,
  "maxIterations": 50,
  "review": true,
  "stuckReminder": true
}
EOF
fi

exit 0
