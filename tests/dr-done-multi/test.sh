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

echo "Phase 2: Execute dr-done workstream"
echo "===================================="

# Check if claude CLI is available
# The CLAUDE_PATH env var can be set to override the default 'claude' command
# Also check common installation location since 'claude' is often a shell alias
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
    echo "Phase 2 SKIPPED: Setup verification passed, but integration test requires claude CLI"
    echo ""
    echo "To run the full integration test, ensure 'claude' is in your PATH or set CLAUDE_PATH"
    echo ""
    echo "Phase 1 (setup verification) PASSED"
    echo "=== Test PASSED (partial - integration test skipped) ==="
    exit 0
fi

# Run claude with the dr-done prompt - let it iterate until workstream is complete
# We use --print to capture output and avoid interactive mode
# The dr-done agent will loop until all tasks are done/stuck

MAX_ITERATIONS=10
ITERATION=0

while [[ $ITERATION -lt $MAX_ITERATIONS ]]; do
    ((++ITERATION))  # Use prefix increment to avoid set -e exit when ITERATION is 0
    echo "Iteration $ITERATION of $MAX_ITERATIONS"

    # Check if there are any pending tasks left
    PENDING=$(find "$TEST_TMP/.dr-done/testwork" -maxdepth 1 -name "*.md" \
        ! -name "*.done.md" \
        ! -name "*.stuck.md" \
        2>/dev/null | wc -l | tr -d ' ')

    if [[ "$PENDING" -eq 0 ]]; then
        echo "No more pending tasks - workstream complete"
        break
    fi

    echo "Found $PENDING pending task(s)"

    # Run claude with the dr-done prompt
    # Using --print for non-interactive mode, --dangerously-skip-permissions to avoid prompts
    # Using --verbose --output-format stream-json to show intermediate output (tool calls, etc.)
    if ! "$CLAUDE_CMD" --print --verbose --output-format stream-json --dangerously-skip-permissions \
        "Follow the instructions in .dr-done/prompt.md to process the next task in the workstream." \
        2>&1; then
        echo "Claude command failed on iteration $ITERATION"
        exit 1
    fi

    echo "Iteration $ITERATION complete"
    echo ""
done

if [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
    echo "WARNING: Reached max iterations ($MAX_ITERATIONS)"
fi

echo ""
echo "Phase 2 PASSED: dr-done workstream executed"
echo ""

echo "Phase 3: Verify expected outcomes"
echo "=================================="

# Verify init.done.md exists
if [[ ! -f "$TEST_TMP/.dr-done/testwork/init.done.md" ]]; then
    echo "FAIL: init.done.md not found"
    ls -la "$TEST_TMP/.dr-done/testwork/"
    exit 1
fi
echo "OK: init.done.md exists"

# Verify at least one 101-*.done.md exists (hello.txt task)
HELLO_TASK=$(find "$TEST_TMP/.dr-done/testwork" -name "101-*.done.md" | head -1)
if [[ -z "$HELLO_TASK" ]]; then
    echo "FAIL: No 101-*.done.md task found"
    ls -la "$TEST_TMP/.dr-done/testwork/"
    exit 1
fi
echo "OK: 101-*.done.md exists: $(basename "$HELLO_TASK")"

# Verify at least one 102-*.done.md exists (goodbye.txt task)
GOODBYE_TASK=$(find "$TEST_TMP/.dr-done/testwork" -name "102-*.done.md" | head -1)
if [[ -z "$GOODBYE_TASK" ]]; then
    echo "FAIL: No 102-*.done.md task found"
    ls -la "$TEST_TMP/.dr-done/testwork/"
    exit 1
fi
echo "OK: 102-*.done.md exists: $(basename "$GOODBYE_TASK")"

# Verify at least one 103-*.stuck.md exists (impossible task)
STUCK_TASK=$(find "$TEST_TMP/.dr-done/testwork" -name "103-*.stuck.md" | head -1)
if [[ -z "$STUCK_TASK" ]]; then
    echo "FAIL: No 103-*.stuck.md task found"
    ls -la "$TEST_TMP/.dr-done/testwork/"
    exit 1
fi
echo "OK: 103-*.stuck.md exists: $(basename "$STUCK_TASK")"

# Verify hello.txt exists and has correct content
if [[ ! -f "$TEST_TMP/hello.txt" ]]; then
    echo "FAIL: hello.txt not found"
    exit 1
fi
HELLO_CONTENT=$(cat "$TEST_TMP/hello.txt")
if [[ "$HELLO_CONTENT" != "Hello from dr-done!" ]]; then
    echo "FAIL: hello.txt has wrong content: '$HELLO_CONTENT'"
    exit 1
fi
echo "OK: hello.txt exists with correct content"

# Verify goodbye.txt exists and has correct content
if [[ ! -f "$TEST_TMP/goodbye.txt" ]]; then
    echo "FAIL: goodbye.txt not found"
    exit 1
fi
GOODBYE_CONTENT=$(cat "$TEST_TMP/goodbye.txt")
if [[ "$GOODBYE_CONTENT" != "Goodbye from dr-done!" ]]; then
    echo "FAIL: goodbye.txt has wrong content: '$GOODBYE_CONTENT'"
    exit 1
fi
echo "OK: goodbye.txt exists with correct content"

# Verify git commits were made with expected patterns
COMMITS=$(git -C "$TEST_TMP" log --oneline)
if ! echo "$COMMITS" | grep -q "\[done\].*init"; then
    echo "FAIL: Missing commit for init task decomposition"
    echo "Commits: $COMMITS"
    exit 1
fi
echo "OK: Found commit for init task"

if ! echo "$COMMITS" | grep -q "\[done\].*101"; then
    echo "FAIL: Missing commit for 101 task"
    echo "Commits: $COMMITS"
    exit 1
fi
echo "OK: Found commit for 101 task"

if ! echo "$COMMITS" | grep -q "\[done\].*102"; then
    echo "FAIL: Missing commit for 102 task"
    echo "Commits: $COMMITS"
    exit 1
fi
echo "OK: Found commit for 102 task"

if ! echo "$COMMITS" | grep -q "\[stuck\].*103"; then
    echo "FAIL: Missing commit for 103 stuck task"
    echo "Commits: $COMMITS"
    exit 1
fi
echo "OK: Found commit for 103 stuck task"

echo ""
echo "Phase 3 PASSED: All verifications complete"
echo ""
echo "=== Test PASSED ==="
