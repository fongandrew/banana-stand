Update the subagent-stop.sh hook with the following changes:

1. Only enforce the "no uncommitted changes" rule if `.claude/dr-done.local.yaml` exists
2. When checking for uncommitted changes, ignore changes in `.dr-done/` directories EXCEPT for the currently active workstream (read from `dr-done.local.yaml`)
3. The hook should still block if there are uncommitted changes in:
   - The active workstream directory (`.dr-done/{workstream}/`)
   - Any files outside of `.dr-done/`

File to modify: `plugins/dr-done/scripts/subagent-stop.sh`

---

## Summary

Updated `subagent-stop.sh` to:
- Only enforce uncommitted changes rule if `.claude/dr-done.local.yaml` exists
- Read the active workstream from the config file
- Filter git status to only block on changes in the active workstream directory or outside `.dr-done/`
- Allow stop when changes are only in other `.dr-done/` subdirectories (not the active workstream)
