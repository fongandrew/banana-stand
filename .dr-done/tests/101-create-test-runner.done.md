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

- [x] `tests/run.sh` exists and is executable
- [x] Script follows the specification in `init.md`

---

## Completion Summary

Created `tests/run.sh` with all specified features:
- Finds test cases (directories containing `test.sh`)
- Copies test case to `.tmp/{case-name}/` for isolation
- Initializes git in temp directory with test user config
- Runs tests with 5-minute timeout
- Supports `-v` verbose mode and test name filtering
- Reports pass/fail summary and exits non-zero on failures
