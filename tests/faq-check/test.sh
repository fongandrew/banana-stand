#!/bin/bash
# Test: faq-check
# Tests for the faq-check plugin PreToolUse architecture
#
# This test validates:
#   1. PreToolUse command rewriting (pre-tool-use.sh)
#   2. Wrapper script execution (faq-wrapper.sh)
#   3. Command + output dual matching (match-checker.sh)
#   4. Opt-out mechanism (FAQ_CHECK=0 prefix)
#   5. Complex command handling (pipes, quotes, redirections)
#   6. Exit code preservation
#   7. match_on behavior (failure/success/any)

set -e

# TEST_TMP is passed as first argument by the test runner
TEST_TMP="$1"
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGIN_ROOT="$REPO_ROOT/plugins/faq-check"

cd "$TEST_TMP"

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

# =============================================================================
# Phase 1: Setup verification
# =============================================================================

echo "Phase 1: Setup verification"
echo "==========================="

# Verify .faq-check directory was copied
if [[ ! -d "$TEST_TMP/.faq-check" ]]; then
    echo "FAIL: .faq-check directory not found"
    exit 1
fi
echo "OK: .faq-check directory exists"

# Verify FAQ files exist
for f in test-error.md test-success.md; do
    if [[ ! -f "$TEST_TMP/.faq-check/$f" ]]; then
        echo "FAIL: $f FAQ not found"
        exit 1
    fi
    echo "OK: $f FAQ exists"
done

# Verify plugin scripts exist
for script in pre-tool-use.sh faq-wrapper.sh match-checker.sh; do
    if [[ ! -f "$PLUGIN_ROOT/scripts/$script" ]]; then
        echo "FAIL: $script not found"
        exit 1
    fi
    echo "OK: $script exists"
done

echo ""
echo "Phase 1 PASSED: Setup verification complete"
echo ""

# =============================================================================
# Phase 2: Unit tests for individual scripts
# =============================================================================

echo "Phase 2: Unit tests for individual scripts"
echo "==========================================="

# -----------------------------------------------------------------------------
# Test pre-tool-use.sh (PreToolUse command rewriting)
# -----------------------------------------------------------------------------

run_test "pre-tool-use.sh: Basic command wrapping"

INPUT='{"tool_name": "Bash", "tool_input": {"command": "npm install"}}'
OUTPUT=$(echo "$INPUT" | "$PLUGIN_ROOT/scripts/pre-tool-use.sh")
if echo "$OUTPUT" | grep -q "faq-wrapper.sh"; then
    pass "Command is wrapped with faq-wrapper.sh"
else
    fail "Command not wrapped" "contains faq-wrapper.sh" "$OUTPUT"
fi

run_test "pre-tool-use.sh: Opt-out with FAQ_CHECK=0"

INPUT='{"tool_name": "Bash", "tool_input": {"command": "FAQ_CHECK=0 npm install"}}'
OUTPUT=$(echo "$INPUT" | "$PLUGIN_ROOT/scripts/pre-tool-use.sh")
if echo "$OUTPUT" | grep -q "faq-wrapper.sh"; then
    fail "Command should not be wrapped with opt-out" "no faq-wrapper.sh" "$OUTPUT"
else
    # Check the command in the hookSpecificOutput structure
    if echo "$OUTPUT" | jq -r '.hookSpecificOutput.updatedInput.command' | grep -q "npm install"; then
        pass "Command passes through without wrapper"
    else
        fail "Stripped command not found" "npm install" "$OUTPUT"
    fi
fi

run_test "pre-tool-use.sh: Empty command passes through"

INPUT='{"tool_name": "Bash", "tool_input": {"command": ""}}'
OUTPUT=$(echo "$INPUT" | "$PLUGIN_ROOT/scripts/pre-tool-use.sh")
if [[ -z "$OUTPUT" ]]; then
    pass "Empty command produces no output (pass-through)"
else
    fail "Empty command should produce no output" "" "$OUTPUT"
fi

run_test "pre-tool-use.sh: Command with single quotes"

INPUT='{"tool_name": "Bash", "tool_input": {"command": "echo '\''hello world'\''"}}'
OUTPUT=$(echo "$INPUT" | "$PLUGIN_ROOT/scripts/pre-tool-use.sh")
if echo "$OUTPUT" | grep -q "faq-wrapper.sh"; then
    pass "Command with single quotes is wrapped"
else
    fail "Command with single quotes not wrapped" "contains faq-wrapper.sh" "$OUTPUT"
fi

# -----------------------------------------------------------------------------
# Test faq-wrapper.sh (wrapper execution)
# -----------------------------------------------------------------------------

run_test "faq-wrapper.sh: Exit code preservation (success)"

EXIT_CODE=$("$PLUGIN_ROOT/scripts/faq-wrapper.sh" "exit 0"; echo $?)
if [[ "$EXIT_CODE" == "0" ]]; then
    pass "Exit code 0 preserved"
else
    fail "Exit code not preserved" "0" "$EXIT_CODE"
fi

run_test "faq-wrapper.sh: Exit code preservation (failure)"

EXIT_CODE=$("$PLUGIN_ROOT/scripts/faq-wrapper.sh" "exit 42" 2>/dev/null; echo $?) || true
# The exit code comes from the subshell
if [[ "$EXIT_CODE" == "42" ]]; then
    pass "Exit code 42 preserved"
else
    fail "Exit code not preserved" "42" "$EXIT_CODE"
fi

run_test "faq-wrapper.sh: Stdout passthrough"

OUTPUT=$("$PLUGIN_ROOT/scripts/faq-wrapper.sh" "echo 'hello stdout'")
if echo "$OUTPUT" | grep -q "hello stdout"; then
    pass "Stdout content passed through"
else
    fail "Stdout not passed through" "hello stdout" "$OUTPUT"
fi

run_test "faq-wrapper.sh: Stderr passthrough"

OUTPUT=$("$PLUGIN_ROOT/scripts/faq-wrapper.sh" "echo 'hello stderr' >&2" 2>&1)
if echo "$OUTPUT" | grep -q "hello stderr"; then
    pass "Stderr content passed through"
else
    fail "Stderr not passed through" "hello stderr" "$OUTPUT"
fi

run_test "faq-wrapper.sh: Complex command with pipes"

OUTPUT=$("$PLUGIN_ROOT/scripts/faq-wrapper.sh" "echo 'line1'; echo 'line2' | grep line2")
if echo "$OUTPUT" | grep -q "line2"; then
    pass "Piped command works"
else
    fail "Piped command failed" "line2" "$OUTPUT"
fi

run_test "faq-wrapper.sh: Command with redirections"

TMPFILE="$TEST_TMP/redirect_test.txt"
"$PLUGIN_ROOT/scripts/faq-wrapper.sh" "echo 'redirected' > $TMPFILE"
if [[ -f "$TMPFILE" ]] && grep -q "redirected" "$TMPFILE"; then
    pass "Redirection works"
else
    fail "Redirection failed" "file with 'redirected'" "$(cat "$TMPFILE" 2>/dev/null || echo 'file not found')"
fi
rm -f "$TMPFILE"

run_test "faq-wrapper.sh: Command with subshell"

OUTPUT=$("$PLUGIN_ROOT/scripts/faq-wrapper.sh" "echo \$(echo nested)")
if echo "$OUTPUT" | grep -q "nested"; then
    pass "Subshell command works"
else
    fail "Subshell command failed" "nested" "$OUTPUT"
fi

run_test "faq-wrapper.sh: FAQ match appended to stderr on failure"

# Run faq-wrapper from TEST_TMP so match-checker.sh can find .faq-check directory
# Using bash -c to ensure proper working directory in all environments
OUTPUT=$(bash -c "cd '$TEST_TMP' && '$PLUGIN_ROOT/scripts/faq-wrapper.sh' 'echo BANANA_STAND_TEST_ERROR && exit 1'" 2>&1) || true
if echo "$OUTPUT" | grep -q "\[FAQ\]"; then
    pass "FAQ match message appended on failure"
else
    fail "FAQ match not appended on failure" "[FAQ]" "$OUTPUT"
fi

run_test "faq-wrapper.sh: FAQ match appended to stderr on success"

# Run faq-wrapper from TEST_TMP so match-checker.sh can find .faq-check directory
OUTPUT=$(bash -c "cd '$TEST_TMP' && '$PLUGIN_ROOT/scripts/faq-wrapper.sh' 'echo BANANA_STAND_TEST_SUCCESS && exit 0'" 2>&1)
if echo "$OUTPUT" | grep -q "\[FAQ\]"; then
    pass "FAQ match message appended on success"
else
    fail "FAQ match not appended on success" "[FAQ]" "$OUTPUT"
fi

run_test "faq-wrapper.sh: No FAQ match for non-matching output"

# Run faq-wrapper from TEST_TMP so match-checker.sh can find .faq-check directory
OUTPUT=$(bash -c "cd '$TEST_TMP' && '$PLUGIN_ROOT/scripts/faq-wrapper.sh' \"echo 'normal output'\"" 2>&1)
if echo "$OUTPUT" | grep -q "\[FAQ\]"; then
    fail "FAQ matched when it should not have" "no [FAQ]" "$OUTPUT"
else
    pass "No FAQ match for non-matching output"
fi

# -----------------------------------------------------------------------------
# Test match-checker.sh (pattern matching)
# All match-checker tests run from TEST_TMP so it can find .faq-check directory
# -----------------------------------------------------------------------------

run_test "match-checker.sh: Literal trigger match"

OUTPUT=$(cd "$TEST_TMP" && FAQ_COMMAND="echo test" FAQ_OUTPUT="BANANA_STAND_TEST_ERROR" FAQ_EXIT_CODE="1" "$PLUGIN_ROOT/scripts/match-checker.sh" 2>/dev/null) || true
if echo "$OUTPUT" | grep -q "test-error.md"; then
    pass "Literal trigger matched"
else
    fail "Literal trigger not matched" "test-error.md" "$OUTPUT"
fi

run_test "match-checker.sh: Regex trigger match (case-insensitive)"

OUTPUT=$(cd "$TEST_TMP" && FAQ_COMMAND="echo test" FAQ_OUTPUT="banana STAND error here" FAQ_EXIT_CODE="1" "$PLUGIN_ROOT/scripts/match-checker.sh" 2>/dev/null) || true
if echo "$OUTPUT" | grep -q "test-error.md"; then
    pass "Regex trigger matched (case-insensitive)"
else
    fail "Regex trigger not matched" "test-error.md" "$OUTPUT"
fi

run_test "match-checker.sh: command_match filtering"

# test-error.md requires command to match /echo|printf/
OUTPUT=$(cd "$TEST_TMP" && FAQ_COMMAND="npm install" FAQ_OUTPUT="BANANA_STAND_TEST_ERROR" FAQ_EXIT_CODE="1" "$PLUGIN_ROOT/scripts/match-checker.sh" 2>/dev/null) || true
if echo "$OUTPUT" | grep -q "test-error.md"; then
    fail "FAQ matched despite command_match not matching" "no match" "$OUTPUT"
else
    pass "command_match filtering works (npm install doesn't match /echo|printf/)"
fi

run_test "match-checker.sh: match_on=failure (failure triggers)"

OUTPUT=$(cd "$TEST_TMP" && FAQ_COMMAND="echo test" FAQ_OUTPUT="BANANA_STAND_TEST_ERROR" FAQ_EXIT_CODE="1" "$PLUGIN_ROOT/scripts/match-checker.sh" 2>/dev/null) || true
if echo "$OUTPUT" | grep -q "test-error.md"; then
    pass "match_on=failure: triggers on failure"
else
    fail "match_on=failure: did not trigger on failure" "test-error.md" "$OUTPUT"
fi

run_test "match-checker.sh: match_on=failure (success doesn't trigger)"

OUTPUT=$(cd "$TEST_TMP" && FAQ_COMMAND="echo test" FAQ_OUTPUT="BANANA_STAND_TEST_ERROR" FAQ_EXIT_CODE="0" "$PLUGIN_ROOT/scripts/match-checker.sh" 2>/dev/null) || true
if echo "$OUTPUT" | grep -q "test-error.md"; then
    fail "match_on=failure: triggered on success" "no match" "$OUTPUT"
else
    pass "match_on=failure: does not trigger on success"
fi

run_test "match-checker.sh: match_on=success (success triggers)"

OUTPUT=$(cd "$TEST_TMP" && FAQ_COMMAND="echo test" FAQ_OUTPUT="BANANA_STAND_TEST_SUCCESS" FAQ_EXIT_CODE="0" "$PLUGIN_ROOT/scripts/match-checker.sh" 2>/dev/null) || true
if echo "$OUTPUT" | grep -q "test-success.md"; then
    pass "match_on=success: triggers on success"
else
    fail "match_on=success: did not trigger on success" "test-success.md" "$OUTPUT"
fi

run_test "match-checker.sh: match_on=success (failure doesn't trigger)"

OUTPUT=$(cd "$TEST_TMP" && FAQ_COMMAND="echo test" FAQ_OUTPUT="BANANA_STAND_TEST_SUCCESS" FAQ_EXIT_CODE="1" "$PLUGIN_ROOT/scripts/match-checker.sh" 2>/dev/null) || true
if echo "$OUTPUT" | grep -q "test-success.md"; then
    fail "match_on=success: triggered on failure" "no match" "$OUTPUT"
else
    pass "match_on=success: does not trigger on failure"
fi

run_test "match-checker.sh: No match returns exit code 1"

EXIT_CODE=$(cd "$TEST_TMP" && FAQ_COMMAND="echo test" FAQ_OUTPUT="nothing special" FAQ_EXIT_CODE="0" "$PLUGIN_ROOT/scripts/match-checker.sh" >/dev/null 2>&1; echo $?) || true
if [[ "$EXIT_CODE" == "1" ]]; then
    pass "No match returns exit code 1"
else
    fail "No match should return exit code 1" "1" "$EXIT_CODE"
fi

run_test "match-checker.sh: Match returns exit code 0"

EXIT_CODE=$(cd "$TEST_TMP" && FAQ_COMMAND="echo test" FAQ_OUTPUT="BANANA_STAND_TEST_ERROR" FAQ_EXIT_CODE="1" "$PLUGIN_ROOT/scripts/match-checker.sh" >/dev/null 2>&1; echo $?) || true
if [[ "$EXIT_CODE" == "0" ]]; then
    pass "Match returns exit code 0"
else
    fail "Match should return exit code 0" "0" "$EXIT_CODE"
fi

# -----------------------------------------------------------------------------
# Test match_on=any behavior
# -----------------------------------------------------------------------------

# Create a temporary FAQ with match_on=any for testing
cat > "$TEST_TMP/.faq-check/test-any.md" << 'EOF'
---
command_match: /echo|printf/
triggers:
  - BANANA_STAND_TEST_ANY
match_on: any
---

# Test Any FAQ

This FAQ triggers regardless of exit code.
EOF

run_test "match-checker.sh: match_on=any (triggers on failure)"

OUTPUT=$(cd "$TEST_TMP" && FAQ_COMMAND="echo test" FAQ_OUTPUT="BANANA_STAND_TEST_ANY" FAQ_EXIT_CODE="1" "$PLUGIN_ROOT/scripts/match-checker.sh" 2>/dev/null) || true
if echo "$OUTPUT" | grep -q "test-any.md"; then
    pass "match_on=any: triggers on failure"
else
    fail "match_on=any: did not trigger on failure" "test-any.md" "$OUTPUT"
fi

run_test "match-checker.sh: match_on=any (triggers on success)"

OUTPUT=$(cd "$TEST_TMP" && FAQ_COMMAND="echo test" FAQ_OUTPUT="BANANA_STAND_TEST_ANY" FAQ_EXIT_CODE="0" "$PLUGIN_ROOT/scripts/match-checker.sh" 2>/dev/null) || true
if echo "$OUTPUT" | grep -q "test-any.md"; then
    pass "match_on=any: triggers on success"
else
    fail "match_on=any: did not trigger on success" "test-any.md" "$OUTPUT"
fi

# Clean up test-any.md
rm -f "$TEST_TMP/.faq-check/test-any.md"

# =============================================================================
# Phase 3: Integration tests
# =============================================================================

echo ""
echo "Phase 3: Integration tests (Claude CLI)"
echo "========================================"

# Check if claude CLI is available
CLAUDE_CMD="${CLAUDE_PATH:-}"
if [[ -z "$CLAUDE_CMD" ]]; then
    if command -v claude &> /dev/null; then
        CLAUDE_CMD="claude"
    elif [[ -x "$HOME/.claude/local/claude" ]]; then
        CLAUDE_CMD="$HOME/.claude/local/claude"
    fi
fi

if [[ -z "$CLAUDE_CMD" ]]; then
    echo "SKIP: claude CLI not found in PATH (set CLAUDE_PATH to override)"
    echo ""
    echo "Phase 3 SKIPPED: Integration tests skipped"
else
    echo "Using Claude CLI: $CLAUDE_CMD"
    echo "Using plugin directory: $PLUGIN_ROOT"
    echo ""

    run_test "Integration: Failure FAQ trigger"

    OUTPUT=$("$CLAUDE_CMD" --print --verbose --output-format stream-json --dangerously-skip-permissions \
        --plugin-dir "$PLUGIN_ROOT" \
        -- "Run this exact bash command and report what happens: bash -c 'echo BANANA_STAND_TEST_ERROR && exit 1'" \
        2>&1) || true

    if echo "$OUTPUT" | grep -q "test-error.md\|additionalContext\|\[FAQ\]"; then
        pass "Failure FAQ trigger detected"
    else
        fail "Failure FAQ trigger not detected" "test-error.md or [FAQ]" "(see verbose output)"
    fi

    run_test "Integration: Success FAQ trigger"

    OUTPUT=$("$CLAUDE_CMD" --print --verbose --output-format stream-json --dangerously-skip-permissions \
        --plugin-dir "$PLUGIN_ROOT" \
        -- "Run this exact bash command and report what happens: bash -c 'echo BANANA_STAND_TEST_SUCCESS && exit 0'" \
        2>&1) || true

    if echo "$OUTPUT" | grep -q "test-success.md\|additionalContext\|\[FAQ\]"; then
        pass "Success FAQ trigger detected"
    else
        fail "Success FAQ trigger not detected" "test-success.md or [FAQ]" "(see verbose output)"
    fi

    run_test "Integration: No FAQ trigger for non-matching output"

    OUTPUT=$("$CLAUDE_CMD" --print --verbose --output-format stream-json --dangerously-skip-permissions \
        --plugin-dir "$PLUGIN_ROOT" \
        -- "Run this exact bash command and report what happens: bash -c 'echo Hello World && exit 0'" \
        2>&1) || true

    if echo "$OUTPUT" | grep -q "test-error.md\|test-success.md"; then
        fail "FAQ matched when it should not have" "no FAQ match" "(see verbose output)"
    else
        pass "No FAQ match for non-matching output"
    fi

    echo ""
    echo "Phase 3 PASSED: Integration tests complete"
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
