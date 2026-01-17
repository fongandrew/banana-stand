#!/bin/bash
# Test: faq-check
# Verifies that the faq-check plugin correctly matches triggers and returns additionalContext

set -e

# TEST_TMP is passed as first argument by the test runner
TEST_TMP="$1"
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGIN_ROOT="$REPO_ROOT/plugins/faq-check"
SCRIPT="$PLUGIN_ROOT/scripts/post-tool-use.sh"

cd "$TEST_TMP"

echo "Setting up test environment"
echo "==========================="

# Set required environment variables
export CLAUDE_PROJECT_DIR="$TEST_TMP"
export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT"

# Create .faq-check directory with test FAQs
mkdir -p "$TEST_TMP/.faq-check"

# FAQ 1: Port conflicts (literal + regex, match_on: failure)
cat > "$TEST_TMP/.faq-check/port-conflicts.md" << 'EOF'
---
triggers:
  - EADDRINUSE
  - /address already in use/i
match_on: failure
---

# Port Conflicts

The port is already in use. Try using a different port.
EOF

# FAQ 2: Success message (match_on: success)
cat > "$TEST_TMP/.faq-check/deploy-success.md" << 'EOF'
---
triggers:
  - deployed successfully
  - /deploy.*complete/i
match_on: success
---

# Deployment Success

Remember to verify the deployment in staging.
EOF

# FAQ 3: Warning pattern (match_on: any) - tests match_on: any behavior
cat > "$TEST_TMP/.faq-check/warning-pattern.md" << 'EOF'
---
triggers:
  - DEPRECATION_WARNING
  - /deprecated.*api/i
match_on: any
---

# Deprecation Warning

This API is deprecated. Consider migrating to the new version.
EOF

# FAQ 4: Another failure FAQ for multiple match testing
cat > "$TEST_TMP/.faq-check/timeout-error.md" << 'EOF'
---
triggers:
  - ETIMEDOUT
  - /connection timed out/i
match_on: failure
---

# Connection Timeout

Check your network connection and try again.
EOF

echo "OK: Test FAQs created"
echo ""

# Helper function to run the script with test input
run_script() {
    local stdout="$1"
    local stderr="$2"
    local exit_code="$3"

    # Escape JSON special characters
    stdout=$(echo "$stdout" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')
    stderr=$(echo "$stderr" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')

    echo "{\"tool_result\": {\"stdout\": \"$stdout\", \"stderr\": \"$stderr\", \"exit_code\": $exit_code}}" | bash "$SCRIPT"
}

echo "Test 1: No match - should return empty"
echo "======================================="
RESULT=$(run_script "Hello world" "" 1 || true)
if [[ -n "$RESULT" ]]; then
    echo "FAIL: Expected empty output, got: $RESULT"
    exit 1
fi
echo "OK: No output for non-matching content"
echo ""

echo "Test 2: Literal match on failure (EADDRINUSE)"
echo "=============================================="
RESULT=$(run_script "Error: listen EADDRINUSE: address already in use" "" 1 || true)
if [[ -z "$RESULT" ]]; then
    echo "FAIL: Expected output for EADDRINUSE match"
    exit 1
fi
if ! echo "$RESULT" | grep -q "port-conflicts.md"; then
    echo "FAIL: Expected port-conflicts.md in output, got: $RESULT"
    exit 1
fi
if ! echo "$RESULT" | grep -q "additionalContext"; then
    echo "FAIL: Expected additionalContext in output, got: $RESULT"
    exit 1
fi
echo "OK: Matched EADDRINUSE literal trigger"
echo ""

echo "Test 3: Regex match with case-insensitive flag"
echo "==============================================="
RESULT=$(run_script "Error: ADDRESS ALREADY IN USE on port 3000" "" 1 || true)
if [[ -z "$RESULT" ]]; then
    echo "FAIL: Expected output for regex match"
    exit 1
fi
if ! echo "$RESULT" | grep -q "port-conflicts.md"; then
    echo "FAIL: Expected port-conflicts.md in output"
    exit 1
fi
echo "OK: Matched case-insensitive regex trigger"
echo ""

echo "Test 4: match_on: failure - should not match on exit 0"
echo "======================================================="
RESULT=$(run_script "Error: listen EADDRINUSE" "" 0 || true)
if [[ -n "$RESULT" ]]; then
    echo "FAIL: Should not match failure FAQ on success, got: $RESULT"
    exit 1
fi
echo "OK: Failure FAQ not matched on exit 0"
echo ""

echo "Test 5: match_on: success - should match on exit 0"
echo "==================================================="
RESULT=$(run_script "Application deployed successfully to production" "" 0 || true)
if [[ -z "$RESULT" ]]; then
    echo "FAIL: Expected output for success match"
    exit 1
fi
if ! echo "$RESULT" | grep -q "deploy-success.md"; then
    echo "FAIL: Expected deploy-success.md in output"
    exit 1
fi
echo "OK: Success FAQ matched on exit 0"
echo ""

echo "Test 6: match_on: success - should not match on exit 1"
echo "======================================================="
RESULT=$(run_script "Application deployed successfully to production" "" 1 || true)
if [[ -n "$RESULT" ]]; then
    echo "FAIL: Should not match success FAQ on failure, got: $RESULT"
    exit 1
fi
echo "OK: Success FAQ not matched on exit 1"
echo ""

echo "Test 7: match_on: any - should match on exit 0"
echo "==============================================="
RESULT=$(run_script "Warning: DEPRECATION_WARNING in module xyz" "" 0 || true)
if [[ -z "$RESULT" ]]; then
    echo "FAIL: Expected output for any match on exit 0"
    exit 1
fi
if ! echo "$RESULT" | grep -q "warning-pattern.md"; then
    echo "FAIL: Expected warning-pattern.md in output"
    exit 1
fi
echo "OK: Any FAQ matched on exit 0"
echo ""

echo "Test 8: match_on: any - should match on exit 1"
echo "==============================================="
RESULT=$(run_script "Error: deprecated API call failed" "" 1 || true)
if [[ -z "$RESULT" ]]; then
    echo "FAIL: Expected output for any match on exit 1"
    exit 1
fi
if ! echo "$RESULT" | grep -q "warning-pattern.md"; then
    echo "FAIL: Expected warning-pattern.md in output"
    exit 1
fi
echo "OK: Any FAQ matched on exit 1"
echo ""

echo "Test 9: Multiple matches - should list files only"
echo "=================================================="
RESULT=$(run_script "EADDRINUSE and ETIMEDOUT errors" "" 1 || true)
if [[ -z "$RESULT" ]]; then
    echo "FAIL: Expected output for multiple matches"
    exit 1
fi
if ! echo "$RESULT" | grep -q "port-conflicts.md"; then
    echo "FAIL: Expected port-conflicts.md in multiple match output"
    exit 1
fi
if ! echo "$RESULT" | grep -q "timeout-error.md"; then
    echo "FAIL: Expected timeout-error.md in multiple match output"
    exit 1
fi
if ! echo "$RESULT" | grep -q "FAQ matches found"; then
    echo "FAIL: Expected 'FAQ matches found' text for multiple matches, got: $RESULT"
    exit 1
fi
echo "OK: Multiple matches listed correctly"
echo ""

echo "Test 10: Single match includes teaser"
echo "======================================"
RESULT=$(run_script "ETIMEDOUT error" "" 1 || true)
if [[ -z "$RESULT" ]]; then
    echo "FAIL: Expected output for single match"
    exit 1
fi
if ! echo "$RESULT" | grep -q "FAQ match:"; then
    echo "FAIL: Expected 'FAQ match:' text for single match, got: $RESULT"
    exit 1
fi
# Check for teaser content (first paragraph)
if ! echo "$RESULT" | grep -q "network"; then
    echo "FAIL: Expected teaser content in output, got: $RESULT"
    exit 1
fi
echo "OK: Single match includes teaser"
echo ""

echo "Test 11: stderr matching"
echo "========================"
RESULT=$(run_script "" "listen EADDRINUSE: address already in use" 1 || true)
if [[ -z "$RESULT" ]]; then
    echo "FAIL: Expected output for stderr match"
    exit 1
fi
if ! echo "$RESULT" | grep -q "port-conflicts.md"; then
    echo "FAIL: Expected port-conflicts.md in output for stderr match"
    exit 1
fi
echo "OK: Matched trigger in stderr"
echo ""

echo "Test 12: No FAQ directory - should exit silently"
echo "================================================="
# Temporarily move the FAQ dir
mv "$TEST_TMP/.faq-check" "$TEST_TMP/.faq-check-backup"
RESULT=$(run_script "EADDRINUSE error" "" 1 || true)
mv "$TEST_TMP/.faq-check-backup" "$TEST_TMP/.faq-check"
if [[ -n "$RESULT" ]]; then
    echo "FAIL: Expected empty output when FAQ dir missing, got: $RESULT"
    exit 1
fi
echo "OK: Silent exit when FAQ directory missing"
echo ""

echo "=== All tests PASSED ==="
