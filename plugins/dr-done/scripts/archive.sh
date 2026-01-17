#!/bin/bash
# Archive script for dr-done workstream
# Called by /dr-done:archive command

set -e

# Parse arguments
WORKSTREAM=""

while [[ $# -gt 0 ]]; do
    case $1 in
        *)
            if [[ -z "$WORKSTREAM" ]]; then
                WORKSTREAM="$1"
            fi
            shift
            ;;
    esac
done

# Validate workstream argument
if [[ -z "$WORKSTREAM" ]]; then
    echo "Error: Workstream name is required" >&2
    echo "Usage: archive.sh <workstream-slug>" >&2
    exit 1
fi

# Get repository root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [[ -z "$REPO_ROOT" ]]; then
    echo "Error: Not in a git repository" >&2
    exit 1
fi

# Validate the workstream exists
WORKSTREAM_DIR="$REPO_ROOT/.dr-done/$WORKSTREAM"
if [[ ! -d "$WORKSTREAM_DIR" ]]; then
    echo "Error: Workstream directory does not exist: $WORKSTREAM_DIR" >&2
    exit 1
fi

# Check for incomplete tasks and warn (non-blocking)
INCOMPLETE_TASKS=$(find "$WORKSTREAM_DIR" -maxdepth 1 -name "*.md" \
    ! -name "*.done.md" \
    ! -name "*.stuck.md" \
    2>/dev/null)

if [[ -n "$INCOMPLETE_TASKS" ]]; then
    echo "Note: This workstream has incomplete tasks:"
    echo "$INCOMPLETE_TASKS" | while read -r task; do
        echo "  - $(basename "$task")"
    done
fi

# Create archive directory if needed
ARCHIVE_DIR="$REPO_ROOT/.dr-done/.archive"
mkdir -p "$ARCHIVE_DIR"

# Move the workstream
mv "$WORKSTREAM_DIR" "$ARCHIVE_DIR/$WORKSTREAM"

# Git add and commit
git add -A
git commit -m "[dr-done] Archive $WORKSTREAM"

echo "Archived workstream '$WORKSTREAM' to .dr-done/.archive/"
