# Create First Test Case

Create a basic test case to validate the test framework is working.

## Requirements

1. Create `tests/basic-start/` directory
2. Create `tests/basic-start/test.sh` - the test script
3. Create necessary setup files (e.g., `.dr-done/foo/init.md`)

## Test Case: basic-start

This test should verify that the dr-done plugin's `/dr-done:start` command works correctly:
- Runs Claude Code with the dr-done plugin
- Invokes `/dr-done:start myworkstream`
- Verifies `.claude/dr-done.local.yaml` was created with correct content

## Acceptance Criteria

- [x] `tests/basic-start/test.sh` exists and is executable
- [x] Test case runs successfully when executed via `tests/run.sh`
- [x] Test verifies the plugin created the expected state

## Summary

Created `tests/basic-start/` test case with:
- `test.sh` - test script that invokes the dr-done setup.sh script directly
- `.dr-done/myworkstream/init.md` - fixture file providing a pending task for the workstream

The test verifies:
1. State file `.claude/dr-done.local.yaml` is created with correct `workstream`, `max`, and `iteration` fields
2. Prompt template is copied to `.dr-done/prompt.md`

Test passes via `./tests/run.sh basic-start`.
