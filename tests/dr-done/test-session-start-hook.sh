#!/bin/bash
# Tests for session-start-hook.sh

set -e

TEST_TMP="$1"
PLUGIN_ROOT="$2"

source "$3"  # test-helpers.sh
source "$4"  # dr-done-helpers.sh

echo "Testing session-start-hook.sh"
echo "============================="

run_test "session-start-hook.sh: No output when not looper"
cleanup_dr_done
setup_dr_done
create_state_file "other-session" 0
OUTPUT=$(mock_hook_input "test-session" | "$PLUGIN_ROOT/scripts/session-start-hook.sh" 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 0 && -z "$OUTPUT" ]]; then
    pass "No output when not looper"
else
    fail "Should have no output when not looper" "empty output" "$OUTPUT"
fi

run_test "session-start-hook.sh: Re-injects loop prompt when looper"
cleanup_dr_done
setup_dr_done
create_state_file "test-session" 0
create_config_file true 50 true
create_task_file "001-test-task.md" "Test task"

OUTPUT=$(mock_hook_input "test-session" | "$PLUGIN_ROOT/scripts/session-start-hook.sh" 2>&1) && exit_code=0 || exit_code=$?
if echo "$OUTPUT" | grep -q "Session resumed" && echo "$OUTPUT" | grep -q "Work on this task"; then
    pass "Re-injects loop prompt when looper"
else
    fail "Should re-inject loop prompt" "contains 'Session resumed' and 'Work on this task'" "$OUTPUT"
fi
