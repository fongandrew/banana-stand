You added the prior missing tests but they are still failing. Unfortunately, there is nothing logged either so I can't quite tell why it's failing.

```
$ ./tests/run.sh
=== Running: dr-done-multi ===
FAILED: dr-done-multi
Phase 1: Setup verification
===========================
[main (root-commit) 66b4f49] [dr-done] checkpoint before starting workstream
 1 file changed, 11 insertions(+)
 create mode 100644 .dr-done/testwork/init.md
Committed existing changes before starting workstream
Copied prompt template to .dr-done/prompt.md
[main 96370df] [dr-done] Ignore dr-done.local.yaml
 1 file changed, 1 insertion(+)
 create mode 100644 .claude/.gitignore
Created .claude/.gitignore to ignore dr-done.local.yaml
dr-done initialized for workstream: testwork (max 50 iterations)
State file created at: /Users/afong/repos/banana-stand/.tmp/dr-done-multi/.claude/dr-done.local.yaml
OK: State file created
OK: State file contains correct workstream
OK: Prompt file copied
OK: init.md exists
OK: init.md contains decomposition instructions
OK: init.md mentions hello.txt task
OK: init.md mentions goodbye.txt task
OK: init.md mentions impossible task

Phase 1 PASSED: Setup verification complete

Phase 2: Execute dr-done workstream
====================================

=== Results: 0 passed, 1 failed ===
```
