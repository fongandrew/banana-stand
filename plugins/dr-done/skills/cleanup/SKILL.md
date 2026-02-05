---
name: cleanup
description: Clean up old tasks from the queue
argument-hint: [optional criteria like "stuck" or "older than X"]
---

Clean up tasks from `.dr-done/tasks/` directory.

**Default behavior (no arguments):** Clean up all `*.done.md` tasks.

**With arguments:** Evaluate the criteria and determine which files to clean up:
- "stuck" - clean up `*.stuck.md` files
- "review" - clean up `*.review.md` files
- "pending" - clean up pending `*.md` files (not .done, .stuck, or .review)
- "all" - clean up all task files
- Time-based (e.g., "older than 7 days", "older than 2 weeks") - parse the time criteria and clean up done tasks older than the specified time

**Use the cleanup script:**
- Call `${CLAUDE_PLUGIN_ROOT}/scripts/cleanup.sh <file-pattern>` to trash files
- The script prefers `trash` command if available, otherwise falls back to `rm`
- You can pass a glob pattern like `.dr-done/tasks/*.done.md` or individual files

**Steps:**
1. Evaluate what files to clean up based on arguments
2. Use Glob or Bash to find matching files if needed
3. Call cleanup.sh with the file pattern or specific files
4. Report how many files were cleaned up
