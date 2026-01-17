Something is not quite right with the test runner. When I run, it finishes way very quickly with no indication it actually called Claude or ran any of the verifications.

$ ./tests/run.sh
=== Running: dr-done-multi ===
PASSED: dr-done-multi

=== Results: 1 passed, 0 failed ===

---

## Resolution

The test.sh script was incomplete - it only had Phase 1 (setup verification) but was missing:
- Phase 2: Actually invoking Claude to execute the dr-done workstream
- Phase 3: Verifying the expected outcomes

Added:
1. **Phase 2** - A loop that runs `claude --print --dangerously-skip-permissions` with the dr-done prompt, iterating until all tasks are complete or stuck (max 10 iterations)
2. **Phase 3** - Verification of all expected outcomes:
   - init.done.md exists
   - 101-*.done.md exists (hello.txt task)
   - 102-*.done.md exists (goodbye.txt task)
   - 103-*.stuck.md exists (impossible task)
   - hello.txt has correct content
   - goodbye.txt has correct content
   - Git commits exist with proper [done]/[stuck] prefixes
