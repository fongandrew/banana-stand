# Update hooks.json for PreToolUse

Update `plugins/faq-check/hooks/hooks.json` to:

1. Remove the existing `PostToolUse` and `PostToolUseFailure` hooks
2. Add a new `PreToolUse` hook that:
   - Matches on Bash tool usage
   - Runs `scripts/pre-tool-use.sh` to rewrite the command parameter
   - Outputs JSON with the modified command wrapped in the FAQ checker

Reference the parent task `090-refactor.md` for full context on the new architecture.

---

## Completion Summary

Updated `plugins/faq-check/hooks/hooks.json`:
- Removed `PostToolUse` and `PostToolUseFailure` hook configurations
- Added `PreToolUse` hook that matches on Bash tool and runs `scripts/pre-tool-use.sh`

The pre-tool-use.sh script will be created in the next task (092).
