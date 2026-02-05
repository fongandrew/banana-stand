#!/bin/bash
# Tests for non-git repository support

set -e

TEST_TMP="$1"
PLUGIN_ROOT="$2"

source "$3"  # test-helpers.sh
source "$4"  # dr-done-helpers.sh

echo "Testing non-git repository support"
echo "==================================="

# Remove git repo for these tests
rm -rf "$TEST_TMP/.git"

run_test "init_dr_done: Works in non-git directory"
cleanup_dr_done
setup_dr_done

# Source common.sh and test init_dr_done
(
    source "$PLUGIN_ROOT/scripts/lib/common.sh"
    init_dr_done
    if [[ -n "$REPO_ROOT" && -d "$DR_DONE_DIR" ]]; then
        exit 0
    else
        exit 1
    fi
) && result=0 || result=$?

if [[ $result -eq 0 ]]; then
    pass "init_dr_done works in non-git directory"
else
    fail "init_dr_done should work in non-git directory" "success" "failed"
fi

run_test "get_repo_root: Returns current directory in non-git repo"
(
    source "$PLUGIN_ROOT/scripts/lib/common.sh"
    root=$(get_repo_root)
    if [[ "$root" == "$TEST_TMP" ]]; then
        exit 0
    else
        echo "Expected: $TEST_TMP, Got: $root" >&2
        exit 1
    fi
) && result=0 || result=$?

if [[ $result -eq 0 ]]; then
    pass "get_repo_root returns current directory"
else
    fail "get_repo_root should return current directory" "$TEST_TMP" "different"
fi

run_test "get_repo_root: Finds .dr-done parent directory"
cleanup_dr_done
mkdir -p "$TEST_TMP/subdir/nested"
setup_dr_done  # Creates .dr-done in TEST_TMP

(
    cd "$TEST_TMP/subdir/nested"
    source "$PLUGIN_ROOT/scripts/lib/common.sh"
    root=$(get_repo_root)
    if [[ "$root" == "$TEST_TMP" ]]; then
        exit 0
    else
        echo "Expected: $TEST_TMP, Got: $root" >&2
        exit 1
    fi
) && result=0 || result=$?

if [[ $result -eq 0 ]]; then
    pass "get_repo_root finds .dr-done parent directory"
else
    fail "Should find .dr-done parent" "$TEST_TMP" "different"
fi

run_test "has_uncommitted_changes: Returns false in non-git repo"
(
    source "$PLUGIN_ROOT/scripts/lib/common.sh"
    init_dr_done
    # Create some files
    echo "test" > "$TEST_TMP/test-file.txt"
    if has_uncommitted_changes; then
        exit 1  # Should not have uncommitted changes in non-git
    else
        exit 0
    fi
) && result=0 || result=$?

if [[ $result -eq 0 ]]; then
    pass "has_uncommitted_changes returns false in non-git repo"
else
    fail "Should return false for non-git repos" "false" "true"
fi

run_test "stop-hook: Works in non-git repo with pending tasks"
cleanup_dr_done
setup_dr_done
create_state_file "test-session" 0
create_config_file true 50 true
create_task_file "001-test-task.md" "Test task"

OUTPUT=$(mock_hook_input "test-session" | "$PLUGIN_ROOT/scripts/stop-hook.sh" 2>&1) && exit_code=0 || exit_code=$?
if echo "$OUTPUT" | jq -e '.decision == "block"' >/dev/null 2>&1 && echo "$OUTPUT" | jq -r '.reason' | grep -q "Work on this task"; then
    pass "stop-hook works in non-git repo"
else
    fail "stop-hook should work in non-git repo" "decision=block with task prompt" "$OUTPUT"
fi

run_test "stop-hook: No uncommitted changes error in non-git repo"
# Even with uncommitted files, should not block on uncommitted changes in non-git
cleanup_dr_done
setup_dr_done
create_state_file "test-session" 0
create_config_file true 50 true
create_task_file "001-test-task.md" "Test task"
echo "uncommitted" > "$TEST_TMP/uncommitted.txt"

OUTPUT=$(mock_hook_input "test-session" | "$PLUGIN_ROOT/scripts/stop-hook.sh" 2>&1) && exit_code=0 || exit_code=$?
if echo "$OUTPUT" | jq -e '.decision == "block"' >/dev/null 2>&1 && ! echo "$OUTPUT" | jq -r '.reason' | grep -q "uncommitted"; then
    pass "No uncommitted changes error in non-git repo"
else
    fail "Should not check uncommitted changes in non-git" "no uncommitted message" "$(echo "$OUTPUT" | jq -r '.reason' | head -c 100)"
fi
rm -f "$TEST_TMP/uncommitted.txt"

run_test "session-start-hook: Works in non-git repo"
cleanup_dr_done
setup_dr_done
create_state_file "test-session" 0
create_config_file true 50 true
create_task_file "001-test-task.md" "Test task"

OUTPUT=$(mock_hook_input "test-session" | "$PLUGIN_ROOT/scripts/session-start-hook.sh" 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 0 ]] && echo "$OUTPUT" | grep -q "Work on this task"; then
    pass "session-start-hook works in non-git repo"
else
    fail "session-start-hook should work in non-git" "task prompt" "$OUTPUT"
fi

run_test "user-prompt-submit-hook: Works in non-git repo"
cleanup_dr_done
setup_dr_done
create_state_file "test-session" 0
create_task_file "001-test-task.stuck.md" "Stuck task"

OUTPUT=$(mock_hook_input "test-session" | "$PLUGIN_ROOT/scripts/user-prompt-submit-hook.sh" 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 0 ]] && echo "$OUTPUT" | grep -qi "stuck"; then
    pass "user-prompt-submit-hook works in non-git repo"
else
    fail "user-prompt-submit-hook should work in non-git" "stuck reminder" "$OUTPUT"
fi

run_test "permission-request-hook: Works in non-git repo"
cleanup_dr_done
setup_dr_done
create_state_file "test-session" 0

OUTPUT=$(mock_hook_input "test-session" | "$PLUGIN_ROOT/scripts/permission-request-hook.sh" 2>&1) && exit_code=0 || exit_code=$?
if echo "$OUTPUT" | jq -e '.hookSpecificOutput.decision.behavior == "deny"' >/dev/null 2>&1; then
    pass "permission-request-hook works in non-git repo"
else
    fail "permission-request-hook should work in non-git" "deny behavior" "$OUTPUT"
fi

run_test "generate-loop-prompt: Works in non-git repo"
cleanup_dr_done
setup_dr_done
create_config_file true 50 true
create_task_file "001-test-task.md" "Test task"

OUTPUT=$("$PLUGIN_ROOT/scripts/generate-loop-prompt.sh" 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 0 ]] && echo "$OUTPUT" | grep -q "Work on this task"; then
    pass "generate-loop-prompt works in non-git repo"
else
    fail "generate-loop-prompt should work in non-git" "task prompt" "$OUTPUT"
fi

run_test "set-looper: Works in non-git repo"
cleanup_dr_done
setup_dr_done
"$PLUGIN_ROOT/scripts/set-looper.sh" "test-session-123" >/dev/null 2>&1 || true
if [[ -f "$TEST_TMP/.dr-done/state.json" ]]; then
    looper=$(jq -r '.looper' "$TEST_TMP/.dr-done/state.json")
    if [[ "$looper" == "test-session-123" ]]; then
        pass "set-looper works in non-git repo"
    else
        fail "set-looper should work in non-git" "looper=test-session-123" "looper=$looper"
    fi
else
    fail "set-looper should create state file" "state.json exists" "not found"
fi
