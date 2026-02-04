#!/bin/bash
# Test: dr-done
# Tests for the dr-done plugin - single-queue task automation
#
# This test validates:
#   1. Plugin structure (hooks, skills, lib scripts)
#   2. Stop hook logic (looper, iteration, queue management)
#   3. Session start hook (resume behavior)
#   4. User prompt submit hook (stuck task reminders)

set -e

# TEST_TMP is passed as first argument by the test runner
# Resolve to canonical path to match git rev-parse --show-toplevel
TEST_TMP="$(cd "$1" && pwd -P)"
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGIN_ROOT="$REPO_ROOT/plugins/dr-done"

cd "$TEST_TMP"

# Initialize as a git repo for the plugin to work
git init -q
git config user.email "test@test.com"
git config user.name "Test User"
# Create initial commit so git operations work properly
touch .gitkeep
git add .gitkeep
git commit -q -m "Initial commit"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

pass() {
    ((++TESTS_PASSED))
    echo "  PASS: $1"
}

fail() {
    ((++TESTS_FAILED))
    echo "  FAIL: $1"
    if [[ -n "${2:-}" ]]; then
        echo "        Expected: $2"
    fi
    if [[ -n "${3:-}" ]]; then
        echo "        Got: $3"
    fi
}

run_test() {
    ((++TESTS_RUN))
    echo ""
    echo "Test $TESTS_RUN: $1"
    echo "$(printf '=%.0s' {1..60})"
}

# dr-done specific helpers
setup_dr_done() {
    mkdir -p "$TEST_TMP/.dr-done/tasks"
    echo "tasks/" > "$TEST_TMP/.dr-done/.gitignore"
}

create_state_file() {
    local looper="$1"
    local iteration="${2:-0}"
    mkdir -p "$TEST_TMP/.dr-done"
    if [[ "$looper" == "null" ]]; then
        cat > "$TEST_TMP/.dr-done/state.json" << EOF
{"looper": null, "iteration": $iteration}
EOF
    else
        cat > "$TEST_TMP/.dr-done/state.json" << EOF
{"looper": "$looper", "iteration": $iteration}
EOF
    fi
}

create_config_file() {
    local git_commit="${1:-true}"
    local max_iterations="${2:-50}"
    local review="${3:-true}"
    mkdir -p "$TEST_TMP/.dr-done"
    cat > "$TEST_TMP/.dr-done/config.json" << EOF
{"gitCommit": $git_commit, "maxIterations": $max_iterations, "review": $review}
EOF
}

create_task_file() {
    local name="$1"
    local content="${2:-Test task}"
    mkdir -p "$TEST_TMP/.dr-done/tasks"
    echo "$content" > "$TEST_TMP/.dr-done/tasks/$name"
}

mock_hook_input() {
    local session_id="$1"
    cat << EOF
{"session_id": "$session_id", "cwd": "$TEST_TMP"}
EOF
}

cleanup_dr_done() {
    rm -rf "$TEST_TMP/.dr-done"
}

# =============================================================================
# Phase 1: Setup verification
# =============================================================================

echo "Phase 1: Setup verification"
echo "==========================="

# Verify plugin structure
if [[ ! -f "$PLUGIN_ROOT/.claude-plugin/plugin.json" ]]; then
    echo "FAIL: .claude-plugin/plugin.json not found"
    exit 1
fi
echo "OK: .claude-plugin/plugin.json exists"

if [[ ! -f "$PLUGIN_ROOT/hooks/hooks.json" ]]; then
    echo "FAIL: hooks/hooks.json not found"
    exit 1
fi
echo "OK: hooks/hooks.json exists"

# Verify hooks.json is valid JSON
if ! jq empty "$PLUGIN_ROOT/hooks/hooks.json" 2>/dev/null; then
    echo "FAIL: hooks/hooks.json is not valid JSON"
    exit 1
fi
echo "OK: hooks/hooks.json is valid JSON"

# Verify lib scripts exist
for script in common.sh template.sh; do
    if [[ ! -f "$PLUGIN_ROOT/scripts/lib/$script" ]]; then
        echo "FAIL: scripts/lib/$script not found"
        exit 1
    fi
    echo "OK: scripts/lib/$script exists"
done

# Verify hook scripts exist and are executable
for script in stop-hook.sh session-start-hook.sh user-prompt-submit-hook.sh permission-request-hook.sh; do
    if [[ ! -f "$PLUGIN_ROOT/scripts/$script" ]]; then
        echo "FAIL: scripts/$script not found"
        exit 1
    fi
    if [[ ! -x "$PLUGIN_ROOT/scripts/$script" ]]; then
        echo "FAIL: scripts/$script is not executable"
        exit 1
    fi
    echo "OK: scripts/$script exists and is executable"
done

# Verify helper scripts exist and are executable
for script in init.sh generate-timestamp.sh read-state.sh find-tasks.sh set-looper.sh generate-loop-prompt.sh; do
    if [[ ! -f "$PLUGIN_ROOT/scripts/$script" ]]; then
        echo "FAIL: scripts/$script not found"
        exit 1
    fi
    if [[ ! -x "$PLUGIN_ROOT/scripts/$script" ]]; then
        echo "FAIL: scripts/$script is not executable"
        exit 1
    fi
    echo "OK: scripts/$script exists and is executable"
done

# Verify skills exist
for skill in init add start do stop unstick; do
    if [[ ! -f "$PLUGIN_ROOT/skills/$skill/SKILL.md" ]]; then
        echo "FAIL: skills/$skill/SKILL.md not found"
        exit 1
    fi
    echo "OK: skills/$skill/SKILL.md exists"
done

# Verify reviewer subagent exists
if [[ ! -f "$PLUGIN_ROOT/agents/reviewer.md" ]]; then
    echo "FAIL: agents/reviewer.md not found"
    exit 1
fi
echo "OK: agents/reviewer.md exists"

echo ""
echo "Phase 1 PASSED: Setup verification complete"
echo ""

# =============================================================================
# Phase 2: Unit tests for hooks
# =============================================================================

echo "Phase 2: Unit tests for hooks"
echo "=============================="

# -----------------------------------------------------------------------------
# Test stop-hook.sh
# -----------------------------------------------------------------------------

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

# -----------------------------------------------------------------------------
# Test session-start-hook.sh
# -----------------------------------------------------------------------------

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

# -----------------------------------------------------------------------------
# Test user-prompt-submit-hook.sh
# -----------------------------------------------------------------------------

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

# -----------------------------------------------------------------------------
# Test permission-request-hook.sh
# -----------------------------------------------------------------------------

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

# -----------------------------------------------------------------------------
# Test set-looper.sh
# -----------------------------------------------------------------------------

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

# -----------------------------------------------------------------------------
# Test generate-loop-prompt.sh
# -----------------------------------------------------------------------------

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

# -----------------------------------------------------------------------------
# Test generate-start-instructions.sh
# -----------------------------------------------------------------------------

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

# =============================================================================
# Summary
# =============================================================================

echo ""
echo "=============================================="
echo "Test Summary"
echo "=============================================="
echo "Tests run:    $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo ""

if [[ $TESTS_FAILED -gt 0 ]]; then
    echo "=== Test FAILED ==="
    exit 1
else
    echo "=== Test PASSED ==="
    exit 0
fi
