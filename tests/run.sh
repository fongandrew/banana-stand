#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="$REPO_ROOT/.tmp"
TIMEOUT=300  # 5 minute default

# Parse arguments
VERBOSE=false
TEST_FILTER=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose) VERBOSE=true; shift ;;
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
    set +e
    if [[ "$VERBOSE" == "true" ]]; then
        timeout "$TIMEOUT" bash "$TEST_SCRIPT" "$TEST_TMP"
        EXIT_CODE=$?
    else
        OUTPUT=$(timeout "$TIMEOUT" bash "$TEST_SCRIPT" "$TEST_TMP" 2>&1)
        EXIT_CODE=$?
    fi
    set -e

    if [[ $EXIT_CODE -eq 0 ]]; then
        echo "PASSED: $CASE_NAME"
        ((PASSED++))
    else
        echo "FAILED: $CASE_NAME"
        if [[ "$VERBOSE" != "true" ]]; then
            echo "$OUTPUT"
        fi
        if [[ $EXIT_CODE -eq 124 ]]; then
            echo "(timed out after ${TIMEOUT}s)"
        fi
        ((FAILED++))
    fi

    echo ""
done

echo "=== Results: $PASSED passed, $FAILED failed ==="
[[ $FAILED -eq 0 ]]
