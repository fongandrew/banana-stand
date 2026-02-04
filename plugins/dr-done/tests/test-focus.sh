#!/bin/bash
# test-focus.sh - Unit tests for focus functionality
# Part of dr-done v2 plugin

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

# Test utilities
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

pass() {
    echo "  ✓ $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
}

fail() {
    echo "  ✗ $1"
    echo "    Expected: $2"
    echo "    Got: $3"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
}

assert_eq() {
    local name="$1"
    local expected="$2"
    local actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        pass "$name"
    else
        fail "$name" "$expected" "$actual"
    fi
}

assert_contains() {
    local name="$1"
    local needle="$2"
    local haystack="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        pass "$name"
    else
        fail "$name" "contains '$needle'" "'$haystack'"
    fi
}

assert_not_contains() {
    local name="$1"
    local needle="$2"
    local haystack="$3"
    if [[ "$haystack" != *"$needle"* ]]; then
        pass "$name"
    else
        fail "$name" "does not contain '$needle'" "'$haystack'"
    fi
}

assert_file_exists() {
    local name="$1"
    local file="$2"
    if [[ -f "$file" ]]; then
        pass "$name"
    else
        fail "$name" "file exists" "file not found: $file"
    fi
}

# Setup test environment
setup() {
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"
    git init -q
    mkdir -p .dr-done/tasks

    # Source the libraries
    source "$PLUGIN_DIR/scripts/lib/common.sh"
    source "$PLUGIN_DIR/scripts/lib/template.sh"
    init_dr_done
    read_config
}

# Cleanup test environment
teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

# ============================================================
# Test: set_focus and get_focus
# ============================================================
test_set_and_get_focus() {
    echo "Test: set_focus and get_focus"
    setup

    # Initially no focus
    local focus=$(get_focus)
    assert_eq "get_focus returns empty initially" "" "$focus"

    # Set focus
    set_focus ".dr-done/tasks/12345-test-task.md"
    focus=$(get_focus)
    assert_eq "get_focus returns set value" ".dr-done/tasks/12345-test-task.md" "$focus"

    # Verify state file structure
    local looper=$(jq -r '.looper' "$STATE_FILE")
    local iteration=$(jq -r '.iteration' "$STATE_FILE")
    assert_eq "looper preserved as null" "null" "$looper"
    assert_eq "iteration preserved" "0" "$iteration"

    teardown
}

# ============================================================
# Test: set_focus preserves existing state
# ============================================================
test_set_focus_preserves_state() {
    echo "Test: set_focus preserves existing looper state"
    setup

    # Set looper first
    set_looper "test-session-123"

    # Now set focus
    set_focus ".dr-done/tasks/my-task.md"

    # Verify both are preserved
    local looper=$(jq -r '.looper' "$STATE_FILE")
    local focus=$(jq -r '.focus' "$STATE_FILE")
    assert_eq "looper preserved" "test-session-123" "$looper"
    assert_eq "focus set" ".dr-done/tasks/my-task.md" "$focus"

    teardown
}

# ============================================================
# Test: clear_focus
# ============================================================
test_clear_focus() {
    echo "Test: clear_focus"
    setup

    # Set focus then clear
    set_focus ".dr-done/tasks/test.md"
    clear_focus

    local focus=$(get_focus)
    assert_eq "focus cleared" "" "$focus"

    # Verify state file doesn't have focus key
    local has_focus=$(jq 'has("focus")' "$STATE_FILE")
    assert_eq "focus key removed from state" "false" "$has_focus"

    teardown
}

# ============================================================
# Test: get_next_task respects focus
# ============================================================
test_get_next_task_with_focus() {
    echo "Test: get_next_task respects focus over alphabetical order"
    setup

    # Create two tasks - earlier one alphabetically
    echo "Task A" > .dr-done/tasks/00001-earlier-task.md
    echo "Task B" > .dr-done/tasks/99999-later-task.md

    # Without focus, should get earlier task
    get_next_task
    assert_contains "without focus gets earliest task" "00001-earlier-task.md" "$NEXT_TASK_FILE"
    assert_eq "type is pending" "pending" "$NEXT_TASK_TYPE"

    # Set focus to later task
    set_focus ".dr-done/tasks/99999-later-task.md"

    # Now should get focused task
    get_next_task
    assert_contains "with focus gets focused task" "99999-later-task.md" "$NEXT_TASK_FILE"
    assert_eq "type is pending" "pending" "$NEXT_TASK_TYPE"

    teardown
}

# ============================================================
# Test: get_next_task clears focus when file doesn't exist
# ============================================================
test_get_next_task_clears_missing_focus() {
    echo "Test: get_next_task clears focus when file doesn't exist"
    setup

    # Create a task
    echo "Task A" > .dr-done/tasks/00001-task.md

    # Set focus to non-existent file
    set_focus ".dr-done/tasks/99999-nonexistent.md"

    # get_next_task should clear focus and fall back
    get_next_task

    # Should get the existing task
    assert_contains "falls back to existing task" "00001-task.md" "$NEXT_TASK_FILE"

    # Focus should be cleared
    local focus=$(get_focus)
    assert_eq "focus cleared" "" "$focus"

    teardown
}

# ============================================================
# Test: get_next_task handles focus on .review.md file
# ============================================================
test_get_next_task_focus_review() {
    echo "Test: get_next_task handles focus on .review.md file"
    setup

    # Create a review task
    echo "Review task" > .dr-done/tasks/12345-my-task.review.md

    # Set focus to it
    set_focus ".dr-done/tasks/12345-my-task.review.md"

    get_next_task
    assert_contains "gets focused review task" "12345-my-task.review.md" "$NEXT_TASK_FILE"
    assert_eq "type is review" "review" "$NEXT_TASK_TYPE"

    teardown
}

# ============================================================
# Test: get_next_task clears focus on .done.md file
# ============================================================
test_get_next_task_focus_done() {
    echo "Test: get_next_task clears focus on .done.md file"
    setup

    # Create a done task and a pending task
    echo "Done task" > .dr-done/tasks/12345-my-task.done.md
    echo "Pending task" > .dr-done/tasks/00001-pending.md

    # Set focus to done task
    set_focus ".dr-done/tasks/12345-my-task.done.md"

    get_next_task

    # Should skip done task and get pending
    assert_contains "skips done task" "00001-pending.md" "$NEXT_TASK_FILE"
    assert_eq "type is pending" "pending" "$NEXT_TASK_TYPE"

    # Focus should be cleared
    local focus=$(get_focus)
    assert_eq "focus cleared after done" "" "$focus"

    teardown
}

# ============================================================
# Test: set-focus.sh script
# ============================================================
test_set_focus_script() {
    echo "Test: set-focus.sh script"
    setup

    # Create a task file
    echo "Test task" > .dr-done/tasks/12345-test.md

    # Run the script
    "$PLUGIN_DIR/scripts/set-focus.sh" ".dr-done/tasks/12345-test.md"

    local focus=$(get_focus)
    assert_eq "script sets focus" ".dr-done/tasks/12345-test.md" "$focus"

    teardown
}

# ============================================================
# Test: set-focus.sh rejects non-existent file
# ============================================================
test_set_focus_script_rejects_missing() {
    echo "Test: set-focus.sh rejects non-existent file"
    setup

    # Try to set focus to non-existent file
    local output
    if output=$("$PLUGIN_DIR/scripts/set-focus.sh" ".dr-done/tasks/nonexistent.md" 2>&1); then
        fail "script should fail for missing file" "exit 1" "exit 0"
    else
        pass "script fails for missing file"
    fi

    assert_contains "error message mentions file" "not found" "$output"

    teardown
}

# ============================================================
# Test: generate-start-instructions.sh --focus-new
# ============================================================
test_generate_start_instructions_focus_new() {
    echo "Test: generate-start-instructions.sh --focus-new"
    setup

    # Set required env var
    export CLAUDE_SESSION_ID="test-session"

    # Run with --focus-new (no tasks exist, but should not error)
    local output
    output=$("$PLUGIN_DIR/scripts/generate-start-instructions.sh" --focus-new)

    # Should not contain error about no pending tasks
    assert_not_contains "no error about pending tasks" "No pending tasks" "$output"

    # Should contain set-focus instruction
    assert_contains "contains set-focus instruction" "set-focus.sh" "$output"

    # Should contain work on file you just created
    assert_contains "contains work instruction" "task file you just created" "$output"

    teardown
}

# ============================================================
# Test: generate-start-instructions.sh without flag errors on no tasks
# ============================================================
test_generate_start_instructions_no_flag() {
    echo "Test: generate-start-instructions.sh without --focus-new errors on no tasks"
    setup

    export CLAUDE_SESSION_ID="test-session"

    # Run without flag (no tasks exist)
    local output
    output=$("$PLUGIN_DIR/scripts/generate-start-instructions.sh")

    # Should contain error about no pending tasks
    assert_contains "error about pending tasks" "No pending tasks" "$output"

    teardown
}

# ============================================================
# Run all tests
# ============================================================
echo "Running focus functionality tests..."
echo ""

test_set_and_get_focus
echo ""

test_set_focus_preserves_state
echo ""

test_clear_focus
echo ""

test_get_next_task_with_focus
echo ""

test_get_next_task_clears_missing_focus
echo ""

test_get_next_task_focus_review
echo ""

test_get_next_task_focus_done
echo ""

test_set_focus_script
echo ""

test_set_focus_script_rejects_missing
echo ""

test_generate_start_instructions_focus_new
echo ""

test_generate_start_instructions_no_flag
echo ""

# Summary
echo "============================================"
echo "Tests run: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo "============================================"

if [[ $TESTS_FAILED -gt 0 ]]; then
    exit 1
fi
