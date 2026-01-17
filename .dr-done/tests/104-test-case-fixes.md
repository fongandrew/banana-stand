Replace `tests/basic-start` with `tests/dr-done-multi`. This test case should have a single workstream and in the `init.md`, let's include instructions to decompose into three additional workstreams (each of which should do something easily verifiable like write a file).

One of the subtasks should contain instructions indicating that the task is impossible -- the goal is to get this task moved to the "stuck" state.

The verification we want here is:

- `init.md` -> `init.done.md`
- Three new subtasks -> 2 of which are in the `.done.md` state and one in the `.stuck.md` state
- Something to verify the 2 done tasks actually completed (look for some file or change they made)
- All of the expected git commits exist
