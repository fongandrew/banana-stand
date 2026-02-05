#!/bin/bash
# Tests for user-prompt-submit-hook.sh and permission-request-hook.sh

set -e

TEST_TMP="$1"
PLUGIN_ROOT="$2"

source "$3"  # test-helpers.sh
source "$4"  # dr-done-helpers.sh

echo "Testing user-prompt-submit-hook.sh and permission-request-hook.sh"
echo "=================================================================="

# user-prompt-submit-hook.sh tests
run_test "user-prompt-submit-hook.sh: No output when no stuck tasks"
cleanup_dr_done
setup_dr_done
create_state_file "other-session" 0
OUTPUT=$(mock_hook_input "test-session" | "$PLUGIN_ROOT/scripts/user-prompt-submit-hook.sh" 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 0 && -z "$OUTPUT" ]]; then
    pass "No output when no stuck tasks"
else
    fail "Should have no output when no stuck tasks" "empty output" "$OUTPUT"
fi

run_test "user-prompt-submit-hook.sh: Outputs reminder for stuck tasks (looper)"
cleanup_dr_done
setup_dr_done
create_state_file "test-session" 0
create_task_file "001-test-task.stuck.md" "Stuck task"

OUTPUT=$(mock_hook_input "test-session" | "$PLUGIN_ROOT/scripts/user-prompt-submit-hook.sh" 2>&1) && exit_code=0 || exit_code=$?
if echo "$OUTPUT" | grep -qi "stuck"; then
    pass "Outputs reminder for stuck tasks (looper)"
else
    fail "Should output stuck task reminder" "contains 'stuck'" "$OUTPUT"
fi

run_test "user-prompt-submit-hook.sh: Outputs reminder for stuck tasks (non-looper)"
cleanup_dr_done
setup_dr_done
create_state_file "other-session" 0
create_task_file "001-test-task.stuck.md" "Stuck task"

OUTPUT=$(mock_hook_input "test-session" | "$PLUGIN_ROOT/scripts/user-prompt-submit-hook.sh" 2>&1) && exit_code=0 || exit_code=$?
if echo "$OUTPUT" | grep -qi "stuck"; then
    pass "Outputs reminder for stuck tasks (non-looper)"
else
    fail "Should output stuck task reminder for non-looper" "contains 'stuck'" "$OUTPUT"
fi

# permission-request-hook.sh tests
run_test "permission-request-hook.sh: No output when no state file"
cleanup_dr_done
OUTPUT=$(mock_hook_input "test-session" | "$PLUGIN_ROOT/scripts/permission-request-hook.sh" 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 0 && -z "$OUTPUT" ]]; then
    pass "No output when no state file"
else
    fail "Should allow permission request with no state file" "exit 0, empty output" "exit $exit_code, output: $OUTPUT"
fi

run_test "permission-request-hook.sh: No output when not looper"
cleanup_dr_done
setup_dr_done
create_state_file "other-session" 0
OUTPUT=$(mock_hook_input "test-session" | "$PLUGIN_ROOT/scripts/permission-request-hook.sh" 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 0 && -z "$OUTPUT" ]]; then
    pass "No output when not looper"
else
    fail "Should allow permission request when not looper" "exit 0, empty output" "exit $exit_code, output: $OUTPUT"
fi

run_test "permission-request-hook.sh: Denies when looper"
cleanup_dr_done
setup_dr_done
create_state_file "test-session" 0

OUTPUT=$(mock_hook_input "test-session" | "$PLUGIN_ROOT/scripts/permission-request-hook.sh" 2>&1) && exit_code=0 || exit_code=$?
if echo "$OUTPUT" | jq -e '.hookSpecificOutput.decision.behavior == "deny"' >/dev/null 2>&1; then
    pass "Denies when looper"
else
    fail "Should deny permission request when looper" "hookSpecificOutput.decision.behavior=deny" "$OUTPUT"
fi

run_test "permission-request-hook.sh: Deny message explains alternatives"
if echo "$OUTPUT" | jq -r '.hookSpecificOutput.decision.message' | grep -q "stuck.md"; then
    pass "Deny message explains alternatives"
else
    fail "Deny message should explain alternatives" "contains 'stuck.md'" "$(echo "$OUTPUT" | jq -r '.hookSpecificOutput.decision.message' | head -c 100)"
fi
