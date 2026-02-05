#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="/tmp/claude/banana-stand-tests"
TIMEOUT=300  # 5 minute default

# Track child PIDs for cleanup on Ctrl+C
CHILD_PID=""
cleanup() {
    if [[ -n "$CHILD_PID" ]]; then
        kill -TERM "$CHILD_PID" 2>/dev/null || true
        wait "$CHILD_PID" 2>/dev/null || true
    fi
    exit 130
}
trap cleanup INT TERM

# Parse arguments
TEST_FILTER=""

while [[ $# -gt 0 ]]; do
    case $1 in
        *) TEST_FILTER="$1"; shift ;;
    esac
done

# Find test cases (directories containing test.sh)
if [[ -n "$TEST_FILTER" ]]; then
    CASES=$(find "$SCRIPT_DIR" -maxdepth 2 -name "test.sh" -path "*$TEST_FILTER*" | sort)
else
    CASES=$(find "$SCRIPT_DIR" -maxdepth 2 -name "test.sh" | sort)
fi

PASSED=0
FAILED=0

for TEST_SCRIPT in $CASES; do
    CASE_DIR=$(dirname "$TEST_SCRIPT")
    CASE_NAME=$(basename "$CASE_DIR")

    # Skip if it's the run.sh directory itself
    [[ "$CASE_NAME" == "tests" ]] && continue

    echo "=== Running: $CASE_NAME ==="

    # Clean and create temp directory for this test
    TEST_TMP="$TMP_DIR/$CASE_NAME"
    rm -rf "$TEST_TMP"
    mkdir -p "$TEST_TMP"

    # Copy test case files (excluding test.sh itself)
    rsync -a --exclude='test.sh' "$CASE_DIR/" "$TEST_TMP/"

    # Initialize git repo for isolated git state
    git init -q "$TEST_TMP"
    git -C "$TEST_TMP" config user.email "test@test.com"
    git -C "$TEST_TMP" config user.name "Test"

    # Run the test with timeout
    # Always show output so users can see what's happening
    # Run in background so we can catch Ctrl+C and clean up
    set +e
    timeout "$TIMEOUT" bash "$TEST_SCRIPT" "$TEST_TMP" &
    CHILD_PID=$!
    wait "$CHILD_PID"
    EXIT_CODE=$?
    CHILD_PID=""
    set -e

    if [[ $EXIT_CODE -eq 0 ]]; then
        echo "PASSED: $CASE_NAME"
        PASSED=$((PASSED + 1))
    else
        echo "FAILED: $CASE_NAME"
        if [[ $EXIT_CODE -eq 124 ]]; then
            echo "(timed out after ${TIMEOUT}s)"
        fi
        FAILED=$((FAILED + 1))
    fi

    echo ""
done

echo "=== Results: $PASSED passed, $FAILED failed ==="
[[ $FAILED -eq 0 ]]
