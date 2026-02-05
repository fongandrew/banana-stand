#!/bin/bash
# Common test helpers for dr-done tests

# Test counters (exported for cross-script tracking)
export TESTS_RUN=${TESTS_RUN:-0}
export TESTS_PASSED=${TESTS_PASSED:-0}
export TESTS_FAILED=${TESTS_FAILED:-0}

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

print_summary() {
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
}
