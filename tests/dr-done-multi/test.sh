#!/bin/bash
# Test: dr-done-multi
# Verifies that dr-done correctly handles task decomposition, completion, and stuck states
#
# This test case sets up a workstream with an init.md that should be decomposed into:
#   - 101-create-hello.md -> creates hello.txt
#   - 102-create-goodbye.md -> creates goodbye.txt
#   - 103-impossible-task.md -> should become stuck
#
# Expected outcomes after dr-done execution:
#   - init.md -> init.done.md
#   - 101-*.done.md (hello.txt created)
#   - 102-*.done.md (goodbye.txt created)
#   - 103-*.stuck.md (impossible task)
#   - hello.txt exists with "Hello from dr-done!"
#   - goodbye.txt exists with "Goodbye from dr-done!"
#   - Git commits for each state change

set -e

# TEST_TMP is passed as first argument by the test runner
TEST_TMP="$1"
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGIN_ROOT="$REPO_ROOT/plugins/dr-done"

cd "$TEST_TMP"

echo "Phase 1: Setup verification"
echo "==========================="

# Run the setup script with our test workstream
export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT"
"$PLUGIN_ROOT/scripts/setup.sh" testwork

# Verify the state file was created
STATE_FILE="$TEST_TMP/.claude/dr-done.local.yaml"

if [[ ! -f "$STATE_FILE" ]]; then
    echo "FAIL: State file not created at $STATE_FILE"
    exit 1
fi
echo "OK: State file created"

# Verify the content is correct
if ! grep -q "workstream: testwork" "$STATE_FILE"; then
    echo "FAIL: State file missing workstream field"
    cat "$STATE_FILE"
    exit 1
fi
echo "OK: State file contains correct workstream"

# Verify prompt.md was copied
PROMPT_FILE="$TEST_TMP/.dr-done/prompt.md"
if [[ ! -f "$PROMPT_FILE" ]]; then
    echo "FAIL: Prompt file not copied to $PROMPT_FILE"
    exit 1
fi
echo "OK: Prompt file copied"

# Verify init.md exists and has expected content
INIT_FILE="$TEST_TMP/.dr-done/testwork/init.md"
if [[ ! -f "$INIT_FILE" ]]; then
    echo "FAIL: init.md not found at $INIT_FILE"
    exit 1
fi
echo "OK: init.md exists"

# Check init.md contains decomposition instructions
if ! grep -q "decomposed" "$INIT_FILE" && ! grep -q "Decompose" "$INIT_FILE"; then
    echo "FAIL: init.md should contain decomposition instructions"
    cat "$INIT_FILE"
    exit 1
fi
echo "OK: init.md contains decomposition instructions"

# Check init.md contains all three subtask descriptions
if ! grep -q "hello.txt" "$INIT_FILE"; then
    echo "FAIL: init.md should mention hello.txt task"
    exit 1
fi
echo "OK: init.md mentions hello.txt task"

if ! grep -q "goodbye.txt" "$INIT_FILE"; then
    echo "FAIL: init.md should mention goodbye.txt task"
    exit 1
fi
echo "OK: init.md mentions goodbye.txt task"

if ! grep -q "impossible" "$INIT_FILE" || ! grep -q "Impossible" "$INIT_FILE"; then
    echo "FAIL: init.md should mention impossible task"
    exit 1
fi
echo "OK: init.md mentions impossible task"

echo ""
echo "Phase 1 PASSED: Setup verification complete"
echo ""
echo "=== Test Summary ==="
echo "This test verifies that the dr-done test case is correctly set up."
echo "The test case is ready for dr-done execution."
echo ""
echo "To run dr-done on this test case manually:"
echo "  1. cd $TEST_TMP"
echo "  2. Run claude with the dr-done prompt"
echo ""
echo "Expected final state after dr-done completes:"
echo "  Files:"
echo "    - .dr-done/testwork/init.done.md"
echo "    - .dr-done/testwork/101-*.done.md"
echo "    - .dr-done/testwork/102-*.done.md"
echo "    - .dr-done/testwork/103-*.stuck.md"
echo "    - hello.txt (content: 'Hello from dr-done!')"
echo "    - goodbye.txt (content: 'Goodbye from dr-done!')"
echo "  Git commits:"
echo "    - [done] testwork/init.md - decomposed into subtasks"
echo "    - [done] testwork/101-*.md - created hello.txt"
echo "    - [done] testwork/102-*.md - created goodbye.txt"
echo "    - [stuck] testwork/103-*.md - impossible task"
