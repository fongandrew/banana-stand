# Update hooks.json for PreToolUse

Update `plugins/faq-check/hooks/hooks.json` to:

1. Remove the existing `PostToolUse` and `PostToolUseFailure` hooks
2. Add a new `PreToolUse` hook that:
   - Matches on Bash tool usage
   - Runs `scripts/pre-tool-use.sh` to rewrite the command parameter
   - Outputs JSON with the modified command wrapped in the FAQ checker

Reference the parent task `090-refactor.md` for full context on the new architecture.
