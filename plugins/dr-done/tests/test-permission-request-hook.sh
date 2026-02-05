#!/bin/bash
# test-permission-request-hook.sh - Unit tests for permission-request-hook.sh
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

# Setup test environment
setup() {
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"
    git init -q
    mkdir -p .dr-done/tasks

    # Source the libraries
    source "$PLUGIN_DIR/scripts/lib/common.sh"
    init_dr_done
}

# Cleanup test environment
teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

# ============================================================
# Test: Permission request allowed when not in autonomous mode
# ============================================================
test_permission_allowed_no_state() {
    echo "Test: Permission request allowed when no state file exists"
    setup

    # Create input JSON for a permission request
    local input=$(cat <<'EOF'
{
  "tool_name": "Bash",
  "session_id": "test-session-123",
  "parameters": {"command": "some-command"}
}
EOF
)

    # Run the hook (no state file exists)
    local exit_code=0
    echo "$input" | "$PLUGIN_DIR/scripts/permission-request-hook.sh" > /dev/null 2>&1 || exit_code=$?

    assert_eq "exit 0 when no state file" "0" "$exit_code"

    teardown
}

# ============================================================
# Test: Permission request allowed when not the looper
# ============================================================
test_permission_allowed_not_looper() {
    echo "Test: Permission request allowed when not the looper"
    setup

    # Set a different session as looper
    set_looper "other-session-456"

    local input=$(cat <<'EOF'
{
  "tool_name": "Bash",
  "session_id": "test-session-123",
  "parameters": {"command": "some-command"}
}
EOF
)

    local exit_code=0
    echo "$input" | "$PLUGIN_DIR/scripts/permission-request-hook.sh" > /dev/null 2>&1 || exit_code=$?

    assert_eq "exit 0 when not looper" "0" "$exit_code"

    teardown
}

# ============================================================
# Test: Permission request denied for looper with Bash
# ============================================================
test_permission_denied_bash() {
    echo "Test: Permission request denied for looper with Bash"
    setup

    # Set this session as looper
    set_looper "test-session-123"

    local input=$(cat <<'EOF'
{
  "tool_name": "Bash",
  "session_id": "test-session-123",
  "parameters": {"command": "some-command"}
}
EOF
)

    local output
    output=$(echo "$input" | "$PLUGIN_DIR/scripts/permission-request-hook.sh" 2>&1)

    # Should contain deny decision
    assert_contains "output contains deny" '"behavior": "deny"' "$output"

    # Should contain general message about sandboxed bash
    assert_contains "mentions sandboxed bash" "sandboxed bash" "$output"

    # Should contain message about settings.json
    assert_contains "mentions settings.json" "settings.json" "$output"

    # Should NOT contain the simpler web-only message
    assert_not_contains "should not have web-only message" "cannot access the web" "$output"

    teardown
}

# ============================================================
# Test: WebFetch gets special simpler message
# ============================================================
test_permission_denied_webfetch() {
    echo "Test: WebFetch gets special simpler denial message"
    setup

    # Set this session as looper
    set_looper "test-session-123"

    local input=$(cat <<'EOF'
{
  "tool_name": "WebFetch",
  "session_id": "test-session-123",
  "parameters": {"url": "https://example.com"}
}
EOF
)

    local output
    output=$(echo "$input" | "$PLUGIN_DIR/scripts/permission-request-hook.sh" 2>&1)

    # Should contain deny decision
    assert_contains "output contains deny" '"behavior": "deny"' "$output"

    # Should contain web-specific message
    assert_contains "mentions web access" "cannot access the web" "$output"

    # Should mention completing without accessing domain
    assert_contains "mentions completing without domain" "without accessing this domain" "$output"

    # Should NOT contain the general message about sandboxed bash
    assert_not_contains "should not mention sandboxed bash" "sandboxed bash" "$output"

    # Should NOT contain settings.json
    assert_not_contains "should not mention settings.json" "settings.json" "$output"

    teardown
}

# ============================================================
# Test: WebSearch gets special simpler message
# ============================================================
test_permission_denied_websearch() {
    echo "Test: WebSearch gets special simpler denial message"
    setup

    # Set this session as looper
    set_looper "test-session-123"

    local input=$(cat <<'EOF'
{
  "tool_name": "WebSearch",
  "session_id": "test-session-123",
  "parameters": {"query": "test query"}
}
EOF
)

    local output
    output=$(echo "$input" | "$PLUGIN_DIR/scripts/permission-request-hook.sh" 2>&1)

    # Should contain deny decision
    assert_contains "output contains deny" '"behavior": "deny"' "$output"

    # Should contain web-specific message
    assert_contains "mentions web access" "cannot access the web" "$output"

    # Should mention completing without accessing domain
    assert_contains "mentions completing without domain" "without accessing this domain" "$output"

    # Should NOT contain the general message about sandboxed bash
    assert_not_contains "should not mention sandboxed bash" "sandboxed bash" "$output"

    # Should NOT contain settings.json
    assert_not_contains "should not mention settings.json" "settings.json" "$output"

    teardown
}

# ============================================================
# Test: Other tools get general message
# ============================================================
test_permission_denied_other_tools() {
    echo "Test: Other tools get general denial message (not web-specific)"
    setup

    # Set this session as looper
    set_looper "test-session-123"

    # Test with Write tool
    local input=$(cat <<'EOF'
{
  "tool_name": "Write",
  "session_id": "test-session-123",
  "parameters": {"file_path": "/some/path"}
}
EOF
)

    local output
    output=$(echo "$input" | "$PLUGIN_DIR/scripts/permission-request-hook.sh" 2>&1)

    # Should contain deny decision
    assert_contains "output contains deny" '"behavior": "deny"' "$output"

    # Should contain general message
    assert_contains "mentions sandboxed bash" "sandboxed bash" "$output"
    assert_contains "mentions settings.json" "settings.json" "$output"

    # Should NOT contain web-specific message
    assert_not_contains "should not have web message" "cannot access the web" "$output"

    teardown
}

# ============================================================
# Test: Permission request with no session ID is allowed
# ============================================================
test_permission_allowed_no_session_id() {
    echo "Test: Permission request allowed when no session ID in input"
    setup

    # Set a session as looper
    set_looper "test-session-123"

    # Input without session_id
    local input=$(cat <<'EOF'
{
  "tool_name": "Bash",
  "parameters": {"command": "some-command"}
}
EOF
)

    local exit_code=0
    echo "$input" | "$PLUGIN_DIR/scripts/permission-request-hook.sh" > /dev/null 2>&1 || exit_code=$?

    assert_eq "exit 0 when no session_id" "0" "$exit_code"

    teardown
}

# ============================================================
# Run all tests
# ============================================================
echo "Running permission-request-hook tests..."
echo ""

test_permission_allowed_no_state
echo ""

test_permission_allowed_not_looper
echo ""

test_permission_denied_bash
echo ""

test_permission_denied_webfetch
echo ""

test_permission_denied_websearch
echo ""

test_permission_denied_other_tools
echo ""

test_permission_allowed_no_session_id
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
