# Tests Workstream

We want to create a test framework or basic system for Claude Code plugins. These will be E2E tests that run against Claude Code itself.

## Directory Structure

```
banana-stand/
├── plugins/
│   └── dr-done/
├── tests/
│   ├── run.sh                  # Test runner
│   └── basic-start/            # A test case (directory)
│       ├── test.sh             # Runs claude + verifies
│       ├── .dr-done/           # Setup files (inline with test.sh)
│       │   └── foo/
│       │       └── init.md
│       └── any-other-files.txt
└── .tmp/                        # Temp copies for test runs (gitignored)
    └── basic-start/            # Copied from tests/basic-start/
```

**Key insight**: `.tmp/` is a sibling of `tests/` and `plugins/`. This means relative paths work identically:
- From `tests/basic-start/`, plugins are at `../../plugins/`
- From `.tmp/basic-start/`, plugins are at `../../plugins/`

No path manipulation needed - test.sh can just use `../../plugins/dr-done`.

## Test Runner (`tests/run.sh`)

```bash
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
        echo "✓ PASSED: $CASE_NAME"
        ((PASSED++))
    else
        echo "✗ FAILED: $CASE_NAME"
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
```

## Test Case Structure

A test case is just a directory containing:
- `test.sh` - the test script (required)
- Any other files needed as initial state

### `test.sh`

Receives one argument: the path to the temp directory where the test runs.

```bash
#!/bin/bash
# test.sh for "basic-start" test case
set -e

TEST_DIR="$1"
cd "$TEST_DIR"

# Relative path to plugins works from either location
PLUGIN_DIR="../../plugins/dr-done"

# Run Claude Code
claude --plugin-dir "$PLUGIN_DIR" \
       --print \
       --dangerously-skip-permissions \
       -p "/dr-done:start myworkstream"

# Verify expected state
[[ -f ".claude/dr-done.local.yaml" ]] || { echo "Missing dr-done.local.yaml"; exit 1; }
grep -q "workstream: myworkstream" ".claude/dr-done.local.yaml" || { echo "Wrong workstream"; exit 1; }

echo "Verification passed"
```

## Key Design Decisions

### 1. Sibling `.tmp/` directory
Makes relative paths work identically in source and temp locations. No environment variables or path rewriting needed.

### 2. Git isolation
Each test gets a fresh `git init`. Tests can verify commits, branches, etc. without affecting the real repo.

### 3. Cleanup at start, not end
Temp directories are cleaned before each test run, not after. This leaves state around for debugging failed tests.

### 4. Generous timeout (5 min default)
Claude Code calls can be slow. Better to wait than flake.

### 5. Verbose mode
`-v` flag shows Claude's output in real time. Without it, output only shown on failure.

### 6. Exit codes
Test passes on exit 0, fails on anything else. Timeout (exit 124) is noted explicitly.

## Verification Patterns

```bash
# Check file exists
[[ -f "path/to/file" ]] || { echo "Missing file"; exit 1; }

# Check file contains string
grep -q "expected" "file.txt" || { echo "Missing content"; exit 1; }

# Check file was renamed
[[ -f ".dr-done/foo/100-task.done.md" ]] || exit 1

# Check git commit was made
git log --oneline | grep -q "\[done\]" || exit 1

# Compare exact content
diff "actual.txt" "expected.txt" || exit 1
```

## Running Tests

```bash
# Run all tests
./tests/run.sh

# Run with verbose output
./tests/run.sh -v

# Run specific test
./tests/run.sh basic-start

# Run tests matching pattern (verbose)
./tests/run.sh -v decompose
```

## Tasks to Implement

1. Create `tests/run.sh` script
2. Add `.tmp/` to `.gitignore`
3. Create first test case to validate the framework
