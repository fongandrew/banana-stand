#!/bin/bash
# Test: basic-start
# Verifies that the dr-done setup.sh script correctly initializes a workstream

set -e

# TEST_TMP is passed as first argument by the test runner
TEST_TMP="$1"
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGIN_ROOT="$REPO_ROOT/plugins/dr-done"

cd "$TEST_TMP"

# Run the setup script with our test workstream
export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT"
"$PLUGIN_ROOT/scripts/setup.sh" myworkstream

# Verify the state file was created
STATE_FILE="$TEST_TMP/.claude/dr-done.local.yaml"

if [[ ! -f "$STATE_FILE" ]]; then
    echo "FAIL: State file not created at $STATE_FILE"
    exit 1
fi

# Verify the content is correct
EXPECTED_WORKSTREAM="workstream: myworkstream"
EXPECTED_MAX="max: 50"
EXPECTED_ITERATION="iteration: 1"

if ! grep -q "$EXPECTED_WORKSTREAM" "$STATE_FILE"; then
    echo "FAIL: State file missing workstream field"
    echo "Content:"
    cat "$STATE_FILE"
    exit 1
fi

if ! grep -q "$EXPECTED_MAX" "$STATE_FILE"; then
    echo "FAIL: State file missing max field"
    echo "Content:"
    cat "$STATE_FILE"
    exit 1
fi

if ! grep -q "$EXPECTED_ITERATION" "$STATE_FILE"; then
    echo "FAIL: State file missing iteration field"
    echo "Content:"
    cat "$STATE_FILE"
    exit 1
fi

# Verify prompt.md was copied
PROMPT_FILE="$TEST_TMP/.dr-done/prompt.md"
if [[ ! -f "$PROMPT_FILE" ]]; then
    echo "FAIL: Prompt file not copied to $PROMPT_FILE"
    exit 1
fi

echo "All checks passed!"
