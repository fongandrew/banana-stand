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
TEST_DIR="$REPO_ROOT/tests/dr-done"
LIB_DIR="$TEST_DIR/lib"

cd "$TEST_TMP"

# Initialize as a git repo for the plugin to work
git init -q
git config user.email "test@test.com"
git config user.name "Test User"
# Create initial commit so git operations work properly
touch .gitkeep
git add .gitkeep
git commit -q -m "Initial commit"

# Source test helpers
source "$LIB_DIR/test-helpers.sh"
source "$LIB_DIR/dr-done-helpers.sh"

# Phase 1: Setup verification
"$TEST_DIR/setup-verification.sh" "$PLUGIN_ROOT"

# Phase 2: Unit tests for hooks
echo "Phase 2: Unit tests for hooks"
echo "=============================="

# Initialize counters before running tests
export TESTS_RUN=0
export TESTS_PASSED=0
export TESTS_FAILED=0

# Run all test modules (they will update the exported counters)
source "$TEST_DIR/test-stop-hook.sh" "$TEST_TMP" "$PLUGIN_ROOT" "$LIB_DIR/test-helpers.sh" "$LIB_DIR/dr-done-helpers.sh"
source "$TEST_DIR/test-session-start-hook.sh" "$TEST_TMP" "$PLUGIN_ROOT" "$LIB_DIR/test-helpers.sh" "$LIB_DIR/dr-done-helpers.sh"
source "$TEST_DIR/test-other-hooks.sh" "$TEST_TMP" "$PLUGIN_ROOT" "$LIB_DIR/test-helpers.sh" "$LIB_DIR/dr-done-helpers.sh"
source "$TEST_DIR/test-helper-scripts.sh" "$TEST_TMP" "$PLUGIN_ROOT" "$LIB_DIR/test-helpers.sh" "$LIB_DIR/dr-done-helpers.sh"

# Print summary
print_summary
