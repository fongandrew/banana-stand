#!/bin/bash
# unstick.sh - Rename all stuck tasks back to pending
# Part of dr-done v2 plugin
#
# Outputs the count of files unstuck

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

init_dr_done

count=0

for stuck_file in "$TASKS_DIR"/*.stuck.md; do
    [[ -e "$stuck_file" ]] || continue

    # Remove .stuck from the filename
    new_name="${stuck_file/.stuck.md/.md}"
    mv "$stuck_file" "$new_name"
    ((count++))
done

echo "$count"
