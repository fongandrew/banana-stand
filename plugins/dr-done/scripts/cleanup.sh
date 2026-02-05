#!/bin/bash
# cleanup.sh - Trash files using available trash command or rm as fallback
#
# Usage: cleanup.sh <file-or-pattern> [file-or-pattern...]
# Examples:
#   cleanup.sh .dr-done/tasks/*.done.md
#   cleanup.sh .dr-done/tasks/20250101T120000-test-task.md
#   cleanup.sh file1.md file2.md file3.md

set -e

if [[ $# -eq 0 ]]; then
    echo "Error: No files specified" >&2
    echo "Usage: cleanup.sh <file-or-pattern> [file-or-pattern...]" >&2
    exit 1
fi

# Determine trash command (prefer trash on macOS, gio trash on Linux, fallback to rm)
if command -v trash >/dev/null 2>&1; then
    TRASH_CMD="trash"
    USE_RM=false
elif command -v gio >/dev/null 2>&1; then
    TRASH_CMD="gio trash"
    USE_RM=false
else
    TRASH_CMD="rm -f"
    USE_RM=true
fi

count=0
files_cleaned=()

# Process all arguments (expand globs)
for pattern in "$@"; do
    # Expand glob pattern
    for file in $pattern; do
        # Check if file exists (glob might not match anything)
        if [[ -e "$file" ]]; then
            if [[ "$USE_RM" == "true" ]]; then
                rm -f "$file"
            else
                # Try trash command, fall back to rm if it fails
                if ! $TRASH_CMD "$file" 2>/dev/null; then
                    rm -f "$file"
                fi
            fi
            files_cleaned+=("$(basename "$file")")
            ((count++))
        fi
    done
done

# Report results
if [[ $count -eq 0 ]]; then
    echo "0"
else
    echo "$count"
fi
