#!/bin/bash
# Tests for helper scripts (set-looper.sh, generate-loop-prompt.sh, generate-start-instructions.sh)

set -e

TEST_TMP="$1"
PLUGIN_ROOT="$2"

source "$3"  # test-helpers.sh
source "$4"  # dr-done-helpers.sh

echo "Testing helper scripts"
echo "======================"

# set-looper.sh tests
run_test "set-looper.sh: Sets looper in state file"
cleanup_dr_done
setup_dr_done
"$PLUGIN_ROOT/scripts/set-looper.sh" "my-session-123" >/dev/null 2>&1 || true
if [[ -f "$TEST_TMP/.dr-done/state.json" ]]; then
    looper=$(jq -r '.looper' "$TEST_TMP/.dr-done/state.json")
    iteration=$(jq -r '.iteration' "$TEST_TMP/.dr-done/state.json")
    if [[ "$looper" == "my-session-123" && "$iteration" == "0" ]]; then
        pass "Sets looper in state file"
    else
        fail "Should set looper correctly" "looper=my-session-123, iteration=0" "looper=$looper, iteration=$iteration"
    fi
else
    fail "Should create state file" "state.json exists" "state.json not found"
fi

run_test "set-looper.sh: Requires session_id argument"
cleanup_dr_done
setup_dr_done
OUTPUT=$("$PLUGIN_ROOT/scripts/set-looper.sh" 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -ne 0 && "$OUTPUT" == *"session_id required"* ]]; then
    pass "Requires session_id argument"
else
    fail "Should require session_id" "exit non-zero, error message" "exit $exit_code, output: $OUTPUT"
fi

# generate-loop-prompt.sh tests
run_test "generate-loop-prompt.sh: Outputs pending task prompt"
cleanup_dr_done
setup_dr_done
create_config_file true 50 true
create_task_file "001-test-task.md" "Test task"

OUTPUT=$("$PLUGIN_ROOT/scripts/generate-loop-prompt.sh" 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 0 ]] && echo "$OUTPUT" | grep -q "Work on this task" && echo "$OUTPUT" | grep -q "001-test-task.md"; then
    pass "Outputs pending task prompt"
else
    fail "Should output pending task prompt" "contains 'Work on this task' and task file" "$OUTPUT"
fi

run_test "generate-loop-prompt.sh: Outputs review prompt for .review.md tasks"
cleanup_dr_done
setup_dr_done
create_config_file true 50 true
create_task_file "001-test-task.review.md" "Completed task"

OUTPUT=$("$PLUGIN_ROOT/scripts/generate-loop-prompt.sh" 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 0 ]] && echo "$OUTPUT" | grep -q "reviewer" && echo "$OUTPUT" | grep -q "001-test-task.review.md"; then
    pass "Outputs review prompt for .review.md tasks"
else
    fail "Should output reviewer prompt" "contains 'reviewer' and task file" "$OUTPUT"
fi

run_test "generate-loop-prompt.sh: Outputs complete message when no tasks"
cleanup_dr_done
setup_dr_done
create_config_file true 50 true
# No task files

OUTPUT=$("$PLUGIN_ROOT/scripts/generate-loop-prompt.sh" 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 0 ]] && echo "$OUTPUT" | grep -q "All tasks complete"; then
    pass "Outputs complete message when no tasks"
else
    fail "Should output complete message" "contains 'All tasks complete'" "$OUTPUT"
fi

run_test "generate-loop-prompt.sh: Uses .done.md when review disabled"
cleanup_dr_done
setup_dr_done
create_config_file true 50 false  # review=false
create_task_file "001-test-task.md" "Test task"

OUTPUT=$("$PLUGIN_ROOT/scripts/generate-loop-prompt.sh" 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 0 ]] && echo "$OUTPUT" | grep -q ".done.md"; then
    pass "Uses .done.md when review disabled"
else
    fail "Should use .done.md extension" "contains '.done.md'" "$OUTPUT"
fi

run_test "generate-loop-prompt.sh: Skips commit instruction when gitCommit disabled"
cleanup_dr_done
setup_dr_done
create_config_file false 50 true  # gitCommit=false
create_task_file "001-test-task.md" "Test task"

OUTPUT=$("$PLUGIN_ROOT/scripts/generate-loop-prompt.sh" 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 0 ]] && ! echo "$OUTPUT" | grep -q "Commit your changes"; then
    pass "Skips commit instruction when gitCommit disabled"
else
    fail "Should not contain commit instruction" "no 'Commit your changes'" "$OUTPUT"
fi

# generate-start-instructions.sh tests
run_test "generate-start-instructions.sh: Error when no pending tasks"
cleanup_dr_done
setup_dr_done
# No task files

OUTPUT=$("$PLUGIN_ROOT/scripts/generate-start-instructions.sh" 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 0 ]] && echo "$OUTPUT" | grep -q "No pending tasks"; then
    pass "Error when no pending tasks"
else
    fail "Should output error for no pending tasks" "contains 'No pending tasks'" "$OUTPUT"
fi

run_test "generate-start-instructions.sh: Inlines session ID when no looper"
cleanup_dr_done
setup_dr_done
create_task_file "001-test-task.md" "Test task"
export CLAUDE_SESSION_ID="test-session-abc123"

OUTPUT=$("$PLUGIN_ROOT/scripts/generate-start-instructions.sh" 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 0 ]] && echo "$OUTPUT" | grep -q 'set-looper.sh "test-session-abc123"'; then
    pass "Inlines session ID when no looper"
else
    fail "Should inline session ID in command" "contains 'set-looper.sh \"test-session-abc123\"'" "$OUTPUT"
fi

run_test "generate-start-instructions.sh: Detects resuming own loop"
cleanup_dr_done
setup_dr_done
create_state_file "test-session-abc123" 5
create_task_file "001-test-task.md" "Test task"
export CLAUDE_SESSION_ID="test-session-abc123"

OUTPUT=$("$PLUGIN_ROOT/scripts/generate-start-instructions.sh" 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 0 ]] && echo "$OUTPUT" | grep -q "resuming your own loop"; then
    pass "Detects resuming own loop"
else
    fail "Should detect resuming own loop" "contains 'resuming your own loop'" "$OUTPUT"
fi

run_test "generate-start-instructions.sh: Detects different session looper"
cleanup_dr_done
setup_dr_done
create_state_file "other-session-xyz" 5
create_task_file "001-test-task.md" "Test task"
export CLAUDE_SESSION_ID="test-session-abc123"

OUTPUT=$("$PLUGIN_ROOT/scripts/generate-start-instructions.sh" 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 0 ]] && echo "$OUTPUT" | grep -q "Existing looper detected" && echo "$OUTPUT" | grep -q "other-session-xyz"; then
    pass "Detects different session looper"
else
    fail "Should detect different session looper" "contains 'Existing looper detected' and 'other-session-xyz'" "$OUTPUT"
fi

run_test "generate-start-instructions.sh: Shows current session ID when different looper"
if echo "$OUTPUT" | grep -q "Your session.*test-session-abc123"; then
    pass "Shows current session ID when different looper"
else
    fail "Should show current session ID" "contains 'Your session' and 'test-session-abc123'" "$OUTPUT"
fi
