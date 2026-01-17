# Create Test Runner Script

Create `tests/run.sh` - the main test runner script for the E2E test framework.

## Requirements

1. Create directory `tests/` at repo root
2. Create `tests/run.sh` with the implementation from the parent task (`init.md`)

## Key Features

- Finds test cases (directories containing `test.sh`)
- Copies test case to `.tmp/{case-name}/` for isolation
- Initializes git in temp directory
- Runs test with timeout (5 min default)
- Supports `-v` verbose mode
- Supports test name filtering
- Reports pass/fail with summary

## Acceptance Criteria

- [ ] `tests/run.sh` exists and is executable
- [ ] Script follows the specification in `init.md`
