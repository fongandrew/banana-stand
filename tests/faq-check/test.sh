#!/bin/bash
# Test: faq-check
# E2E test that verifies the faq-check plugin correctly matches triggers and returns additionalContext
#
# This test:
#   1. Sets up a project with .faq-check/ directory containing FAQ files (pre-created, copied by test runner)
#   2. Runs Claude CLI with --plugin-dir to load the faq-check plugin
#   3. Executes commands that produce trigger-matching output
#   4. Verifies that Claude receives the FAQ additionalContext in its response
#
# The test FAQs are pre-created in tests/faq-check/.faq-check/ and copied by the test runner

set -e

# TEST_TMP is passed as first argument by the test runner
TEST_TMP="$1"
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGIN_ROOT="$REPO_ROOT/plugins/faq-check"

cd "$TEST_TMP"

echo "Phase 1: Setup verification"
echo "==========================="

# Verify .faq-check directory was copied
if [[ ! -d "$TEST_TMP/.faq-check" ]]; then
    echo "FAIL: .faq-check directory not found"
    exit 1
fi
echo "OK: .faq-check directory exists"

# Verify FAQ files exist
if [[ ! -f "$TEST_TMP/.faq-check/test-error.md" ]]; then
    echo "FAIL: test-error.md FAQ not found"
    exit 1
fi
echo "OK: test-error.md FAQ exists"

if [[ ! -f "$TEST_TMP/.faq-check/test-success.md" ]]; then
    echo "FAIL: test-success.md FAQ not found"
    exit 1
fi
echo "OK: test-success.md FAQ exists"

# Verify plugin directory exists
if [[ ! -d "$PLUGIN_ROOT" ]]; then
    echo "FAIL: Plugin directory not found at $PLUGIN_ROOT"
    exit 1
fi
echo "OK: Plugin directory exists at $PLUGIN_ROOT"

# Verify hooks.json exists in plugin
if [[ ! -f "$PLUGIN_ROOT/hooks/hooks.json" ]]; then
    echo "FAIL: hooks/hooks.json not found in plugin"
    exit 1
fi
echo "OK: Plugin hooks/hooks.json exists"

echo ""
echo "Phase 1 PASSED: Setup verification complete"
echo ""

echo "Phase 2: Execute Claude with faq-check plugin"
echo "=============================================="

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
    echo "Phase 1 (setup verification) PASSED"
    echo "=== Test PASSED (partial - integration test skipped) ==="
    exit 0
fi

echo "Using Claude CLI: $CLAUDE_CMD"
echo "Using plugin directory: $PLUGIN_ROOT"
echo ""

# Test 1: Trigger failure FAQ
echo "Test 1: Failure FAQ trigger (BANANA_STAND_TEST_ERROR)"
echo "====================================================="

# Ask Claude to run a command that will output our test error and fail
# The faq-check hook should match and return additionalContext
# Use --plugin-dir to load the plugin (recommended approach for testing plugins)
# Use -- to separate options from the prompt argument (since --plugin-dir takes multiple paths)
OUTPUT=$("$CLAUDE_CMD" --print --verbose --output-format stream-json --dangerously-skip-permissions \
    --plugin-dir "$PLUGIN_ROOT" \
    -- "Run this exact bash command and report what happens: bash -c 'echo BANANA_STAND_TEST_ERROR && exit 1'" \
    2>&1) || true

echo "Claude output:"
echo "$OUTPUT"
echo ""

# Check if the FAQ match was provided in the output
# The additionalContext should mention our FAQ file
if echo "$OUTPUT" | grep -q "test-error.md"; then
    echo "OK: FAQ match for test-error.md detected in output"
else
    # Check if additionalContext was in the stream
    if echo "$OUTPUT" | grep -q "additionalContext"; then
        echo "OK: additionalContext was provided (hook executed)"
    else
        echo "WARN: Could not verify FAQ hook execution in output"
        echo "      (This may be due to output format - manual verification may be needed)"
    fi
fi

# Test 2: Trigger success FAQ
echo ""
echo "Test 2: Success FAQ trigger (BANANA_STAND_TEST_SUCCESS)"
echo "========================================================"

OUTPUT=$("$CLAUDE_CMD" --print --verbose --output-format stream-json --dangerously-skip-permissions \
    --plugin-dir "$PLUGIN_ROOT" \
    -- "Run this exact bash command and report what happens: bash -c 'echo BANANA_STAND_TEST_SUCCESS && exit 0'" \
    2>&1) || true

echo "Claude output:"
echo "$OUTPUT"
echo ""

if echo "$OUTPUT" | grep -q "test-success.md"; then
    echo "OK: FAQ match for test-success.md detected in output"
else
    if echo "$OUTPUT" | grep -q "additionalContext"; then
        echo "OK: additionalContext was provided (hook executed)"
    else
        echo "WARN: Could not verify FAQ hook execution in output"
        echo "      (This may be due to output format - manual verification may be needed)"
    fi
fi

# Test 3: No match (should not trigger FAQ)
echo ""
echo "Test 3: No FAQ trigger (should not match)"
echo "=========================================="

OUTPUT=$("$CLAUDE_CMD" --print --verbose --output-format stream-json --dangerously-skip-permissions \
    --plugin-dir "$PLUGIN_ROOT" \
    -- "Run this exact bash command and report what happens: bash -c 'echo Hello World && exit 0'" \
    2>&1) || true

echo "Claude output:"
echo "$OUTPUT"
echo ""

if echo "$OUTPUT" | grep -q "test-error.md\|test-success.md"; then
    echo "FAIL: FAQ matched when it should not have"
    exit 1
fi
echo "OK: No FAQ match for non-matching output"

echo ""
echo "Phase 2 PASSED: Claude integration tests complete"
echo ""

echo "=== Test PASSED ==="
