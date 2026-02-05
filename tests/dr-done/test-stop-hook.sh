#!/bin/bash
# Tests for stop-hook.sh

set -e

TEST_TMP="$1"
PLUGIN_ROOT="$2"

source "$3"  # test-helpers.sh
source "$4"  # dr-done-helpers.sh

echo "Testing stop-hook.sh"
echo "===================="

run_test "stop-hook.sh: No state file allows stop"
cleanup_dr_done
OUTPUT=$(mock_hook_input "test-session" | "$PLUGIN_ROOT/scripts/stop-hook.sh" 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 0 && -z "$OUTPUT" ]]; then
    pass "No state file allows stop (no output)"
else
    fail "Should allow stop with no state file" "exit 0, empty output" "exit $exit_code, output: $OUTPUT"
fi

run_test "stop-hook.sh: Not the looper allows stop"
cleanup_dr_done
setup_dr_done
create_state_file "other-session" 0
OUTPUT=$(mock_hook_input "test-session" | "$PLUGIN_ROOT/scripts/stop-hook.sh" 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 0 && -z "$OUTPUT" ]]; then
    pass "Not the looper allows stop"
else
    fail "Should allow stop when not looper" "exit 0, empty output" "exit $exit_code, output: $OUTPUT"
fi

run_test "stop-hook.sh: Looper with pending tasks blocks"
cleanup_dr_done
setup_dr_done
create_state_file "test-session" 0
create_config_file true 50 true
create_task_file "001-test-task.md" "Test task"
# Make a commit so there are no uncommitted changes
git add -A && git commit -m "test" -q 2>/dev/null || true

OUTPUT=$(mock_hook_input "test-session" | "$PLUGIN_ROOT/scripts/stop-hook.sh" 2>&1) && exit_code=0 || exit_code=$?
if echo "$OUTPUT" | jq -e '.decision == "block"' >/dev/null 2>&1; then
    pass "Looper with pending tasks blocks"
else
    fail "Should block with pending tasks" "decision=block" "$OUTPUT"
fi

run_test "stop-hook.sh: Block message contains loop prompt"
if echo "$OUTPUT" | jq -r '.reason' | grep -q "Work on this task"; then
    pass "Block message contains loop prompt"
else
    fail "Block message missing loop prompt" "contains 'Work on this task'" "$(echo "$OUTPUT" | jq -r '.reason' | head -c 100)"
fi

run_test "stop-hook.sh: Looper with review tasks blocks with reviewer prompt"
cleanup_dr_done
setup_dr_done
create_state_file "test-session" 0
create_config_file true 50 true
create_task_file "001-test-task.review.md" "Completed task"
git add -A && git commit -m "test" -q 2>/dev/null || true

OUTPUT=$(mock_hook_input "test-session" | "$PLUGIN_ROOT/scripts/stop-hook.sh" 2>&1) && exit_code=0 || exit_code=$?
if echo "$OUTPUT" | jq -e '.decision == "block"' >/dev/null 2>&1 && echo "$OUTPUT" | jq -r '.reason' | grep -q "reviewer"; then
    pass "Looper with review tasks blocks with reviewer prompt"
else
    fail "Should block with reviewer prompt" "decision=block, contains 'reviewer'" "$OUTPUT"
fi

run_test "stop-hook.sh: Looper with empty queue clears looper"
cleanup_dr_done
setup_dr_done
create_state_file "test-session" 0
create_config_file true 50 true
create_task_file "001-test-task.done.md" "Completed task"
git add -A && git commit -m "test" -q 2>/dev/null || true

OUTPUT=$(mock_hook_input "test-session" | "$PLUGIN_ROOT/scripts/stop-hook.sh" 2>&1) && exit_code=0 || exit_code=$?
looper=$(jq -r '.looper' "$TEST_TMP/.dr-done/state.json")
if [[ $exit_code -eq 0 && "$looper" == "null" ]]; then
    pass "Looper with empty queue clears looper"
else
    fail "Should clear looper when queue empty" "looper=null" "looper=$looper"
fi

run_test "stop-hook.sh: Max iterations clears looper"
cleanup_dr_done
setup_dr_done
create_state_file "test-session" 50  # At max iterations
create_config_file true 50 true
create_task_file "001-test-task.md" "Test task"
git add -A && git commit -m "test" -q 2>/dev/null || true

OUTPUT=$(mock_hook_input "test-session" | "$PLUGIN_ROOT/scripts/stop-hook.sh" 2>&1) && exit_code=0 || exit_code=$?
looper=$(jq -r '.looper' "$TEST_TMP/.dr-done/state.json")
if [[ $exit_code -eq 0 && "$looper" == "null" ]]; then
    pass "Max iterations clears looper"
else
    fail "Should clear looper at max iterations" "looper=null" "looper=$looper"
fi

run_test "stop-hook.sh: Uncommitted changes blocks"
cleanup_dr_done
setup_dr_done
create_state_file "test-session" 0
create_config_file true 50 true
create_task_file "001-test-task.md" "Test task"
# Create uncommitted changes
echo "uncommitted" > "$TEST_TMP/uncommitted.txt"
git add -A  # Stage but don't commit

OUTPUT=$(mock_hook_input "test-session" | "$PLUGIN_ROOT/scripts/stop-hook.sh" 2>&1) && exit_code=0 || exit_code=$?
if echo "$OUTPUT" | jq -e '.decision == "block"' >/dev/null 2>&1 && echo "$OUTPUT" | jq -r '.reason' | grep -q "uncommitted"; then
    pass "Uncommitted changes blocks"
else
    fail "Should block with uncommitted changes" "decision=block, contains 'uncommitted'" "$OUTPUT"
fi
rm -f "$TEST_TMP/uncommitted.txt"
git reset -q HEAD 2>/dev/null || true

run_test "stop-hook.sh: Increments iteration counter"
cleanup_dr_done
setup_dr_done
create_state_file "test-session" 5
create_config_file true 50 true
create_task_file "001-test-task.md" "Test task"
git add -A && git commit -m "test" -q 2>/dev/null || true

mock_hook_input "test-session" | "$PLUGIN_ROOT/scripts/stop-hook.sh" >/dev/null 2>&1 || true
iteration=$(jq -r '.iteration' "$TEST_TMP/.dr-done/state.json")
if [[ "$iteration" == "6" ]]; then
    pass "Increments iteration counter"
else
    fail "Should increment iteration" "6" "$iteration"
fi
