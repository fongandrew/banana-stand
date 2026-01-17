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

- [ ] `tests/basic-start/test.sh` exists and is executable
- [ ] Test case runs successfully when executed via `tests/run.sh`
- [ ] Test verifies the plugin created the expected state
