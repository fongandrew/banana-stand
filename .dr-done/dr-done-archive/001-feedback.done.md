This is currently done via prompts but let's have the archival and git commit bits function via a bash script so it's more deterministic

---

## Summary

Created `plugins/dr-done/scripts/archive.sh` bash script that handles:
- Argument parsing and validation
- Workstream directory existence check
- Warning about incomplete tasks (non-blocking)
- Creating `.dr-done/.archive/` directory if needed
- Moving the workstream to the archive
- Git add and commit with proper message format

Updated `plugins/dr-done/commands/archive.md` to invoke the script instead of having prompt-based instructions for each step.
