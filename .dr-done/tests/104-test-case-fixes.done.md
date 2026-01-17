Replace `tests/basic-start` with `tests/dr-done-multi`. This test case should have a single workstream and in the `init.md`, let's include instructions to decompose into three additional workstreams (each of which should do something easily verifiable like write a file).

One of the subtasks should contain instructions indicating that the task is impossible -- the goal is to get this task moved to the "stuck" state.

The verification we want here is:

- `init.md` -> `init.done.md`
- Three new subtasks -> 2 of which are in the `.done.md` state and one in the `.stuck.md` state
- Something to verify the 2 done tasks actually completed (look for some file or change they made)
- All of the expected git commits exist

---

## Summary

Replaced `tests/basic-start` with `tests/dr-done-multi`. The test case includes:

- A `testwork` workstream with `init.md` containing decomposition instructions for 3 subtasks:
  1. Create `hello.txt` with content "Hello from dr-done!"
  2. Create `goodbye.txt` with content "Goodbye from dr-done!"
  3. An impossible task (read from nonexistent path) that should become stuck

- Updated `test.sh` with comprehensive setup verification:
  - Verifies state file creation
  - Verifies prompt.md is copied
  - Verifies init.md exists and contains expected content (decomposition instructions, all three task descriptions)
  - Documents expected final state after dr-done execution

The test passes setup verification. The expected outcomes after dr-done runs are documented in the test output.
