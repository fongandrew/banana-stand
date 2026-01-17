Your work in 070-tests is more unit test than E2E. We really do want to test against an actual live instance of Claude. Look at how the test for dr-done-multi works.

Also, the test doesn't need to write content out. We can just create the contents we expect in an .faq directory and the test runner will copy everything as needd.

---

## Work Completed

Updated `tests/faq-check/test.sh` to be a proper E2E test:

1. **Removed manual settings.json creation** - The old test was manually writing `.claude/settings.json` to configure hooks, which was flagged as a code smell.

2. **Now uses `--plugin-dir` flag** - Per https://code.claude.com/docs/en/plugins, the `--plugin-dir` flag is the recommended approach for testing plugins. All Claude CLI commands now use:
   ```bash
   --plugin-dir "$PLUGIN_ROOT"
   ```

3. **Added `--` separator** - Since `--plugin-dir` takes multiple paths (`<paths...>`), the prompt was being consumed as another path. Added `--` to clearly separate options from the positional prompt argument.

4. **Preserved pre-created .faq-check directory** - The test FAQs in `tests/faq-check/.faq-check/` are already pre-created and copied by the test runner (as noted in the task).

5. **Added plugin verification checks** - Phase 1 now verifies the plugin directory and hooks.json exist before running integration tests.

## Stuck Reason

Cannot verify the tests work because running the test requires unsandboxed bash (the Claude CLI writes to `~/.claude.json` which is outside the allowed sandbox paths). The dr-done autonomous loop cannot request permissions for unsandboxed execution.

**To complete verification**, manually run:
```bash
./tests/run.sh faq-check
```

The test structure matches dr-done-multi - it runs against a live Claude instance using `--plugin-dir` to load the plugin, rather than manually configuring settings.json.
