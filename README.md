# banana-stand

Development repository for Claude Code plugins and experimental features.

## Contents

### Plugins

#### dr-done

Single-queue task automation with review workflow for Claude Code.

**Features:**
- Task queue management with `.md` file-based tasks
- Automated looping through pending tasks
- Built-in review workflow (`.review.md` → `.done.md`)
- Stuck task detection and recovery (`.stuck.md`)
- Git commit integration (optional)
- Works in both git and non-git repositories

**Skills:**
- `/dr-done:init` - Initialize the dr-done system
- `/dr-done:add` - Add a new task to the queue
- `/dr-done:start` - Start processing the task queue
- `/dr-done:do` - Work on a specific task by ID
- `/dr-done:stop` - Stop the task queue loop
- `/dr-done:unstick` - Rename stuck tasks back to pending

**Configuration** (`.dr-done/config.json`):
```json
{
  "gitCommit": true,      // Require git commits after each task
  "maxIterations": 50,    // Maximum loop iterations before auto-stop
  "review": true          // Enable review workflow (.review.md)
}
```

**Task Workflow:**
1. Create task: `.dr-done/tasks/TIMESTAMP-slug.md`
2. Work on task: Claude processes the task
3. Mark complete: Rename to `.review.md` (if review enabled) or `.done.md`
4. Review: Reviewer agent validates and renames to `.done.md`
5. Mark stuck: Rename to `.stuck.md` if help needed

## Development

### Running Tests

```bash
bash tests/run.sh
```

Run specific test:
```bash
bash tests/run.sh tests/dr-done
```

### Test Structure

The dr-done plugin includes comprehensive test coverage:
- `test.sh` - Main test orchestrator
- `lib/test-helpers.sh` - Common test framework
- `lib/dr-done-helpers.sh` - dr-done specific helpers
- `setup-verification.sh` - Plugin structure verification
- `test-stop-hook.sh` - Stop hook tests (9 tests)
- `test-session-start-hook.sh` - Session start hook tests (2 tests)
- `test-other-hooks.sh` - Submit/permission hook tests (7 tests)
- `test-helper-scripts.sh` - Helper script tests (12 tests)
- `test-non-git.sh` - Non-git repository tests (11 tests)

Total: 41 tests covering all hooks, scripts, and edge cases.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Author

Andrew Fong
