#!/bin/bash
# generate-loop-prompt.sh - Generate the main loop prompt for the next task
# Part of dr-done v2 plugin
#
# This outputs the exact same prompt used by stop-hook.sh and session-start-hook.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/template.sh"

init_dr_done
read_config
get_next_task

case "$NEXT_TASK_TYPE" in
    review)
        build_review_prompt "$NEXT_TASK_FILE"
        ;;
    pending)
        build_pending_prompt "$NEXT_TASK_FILE"
        ;;
    *)
        echo "All tasks complete. Nothing to do."
        ;;
esac
