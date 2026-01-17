#!/bin/bash
# Setup script for dr-done workstream
# Called by /dr-done:start command

set -e

# Determine plugin root - use CLAUDE_PLUGIN_ROOT if set, otherwise derive from script location
if [[ -z "$CLAUDE_PLUGIN_ROOT" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    CLAUDE_PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
fi

# Parse arguments
WORKSTREAM=""
MAX_ITERATIONS=50

while [[ $# -gt 0 ]]; do
    case $1 in
        --max)
            MAX_ITERATIONS="$2"
            shift 2
            ;;
        *)
            if [[ -z "$WORKSTREAM" ]]; then
                WORKSTREAM="$1"
            fi
            shift
            ;;
    esac
done

# Get repository root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [[ -z "$REPO_ROOT" ]]; then
    echo "Error: Not in a git repository" >&2
    exit 1
fi

# Early commit: Check for uncommitted changes and commit them
if [[ -n $(git status --porcelain) ]]; then
    git add -A
    git commit -m "[dr-done] checkpoint before starting workstream"
    echo "Committed existing changes before starting workstream"
fi

# Repo Setup: Create .dr-done directory if it doesn't exist
DR_DONE_DIR="$REPO_ROOT/.dr-done"
if [[ ! -d "$DR_DONE_DIR" ]]; then
    mkdir -p "$DR_DONE_DIR"
    echo "Created .dr-done directory"
fi

# Copy prompt template if it doesn't exist
PROMPT_FILE="$DR_DONE_DIR/prompt.md"
if [[ ! -f "$PROMPT_FILE" ]]; then
    TEMPLATE_FILE="$CLAUDE_PLUGIN_ROOT/templates/prompt.md"
    if [[ -f "$TEMPLATE_FILE" ]]; then
        cp "$TEMPLATE_FILE" "$PROMPT_FILE"
        echo "Copied prompt template to .dr-done/prompt.md"
    else
        echo "Warning: Template not found at $TEMPLATE_FILE" >&2
    fi
fi

# If no workstream specified, just do setup and exit
if [[ -z "$WORKSTREAM" ]]; then
    echo "Setup complete. No workstream specified."
    exit 0
fi

# Workstream Validation: Check that workstream directory exists
WORKSTREAM_DIR="$DR_DONE_DIR/$WORKSTREAM"
if [[ ! -d "$WORKSTREAM_DIR" ]]; then
    echo "Error: Workstream directory does not exist: $WORKSTREAM_DIR" >&2
    exit 1
fi

# Check for at least one .md file that is not .done.md or .stuck.md
PENDING_TASKS=$(find "$WORKSTREAM_DIR" -maxdepth 1 -name "*.md" \
    ! -name "*.done.md" \
    ! -name "*.stuck.md" \
    2>/dev/null | head -1)

if [[ -z "$PENDING_TASKS" ]]; then
    echo "Error: No pending tasks in workstream: $WORKSTREAM" >&2
    echo "All tasks are either .done.md or .stuck.md" >&2
    exit 1
fi

# Create state file
CLAUDE_DIR="$REPO_ROOT/.claude"
mkdir -p "$CLAUDE_DIR"

STATE_FILE="$CLAUDE_DIR/dr-done.local.yaml"
cat > "$STATE_FILE" << EOF
max: $MAX_ITERATIONS
iteration: 1
workstream: $WORKSTREAM
EOF

echo "dr-done initialized for workstream: $WORKSTREAM (max $MAX_ITERATIONS iterations)"
echo "State file created at: $STATE_FILE"
