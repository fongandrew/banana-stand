# Implement hooks.json

Create `plugins/faq-check/hooks/hooks.json` with PostToolUse hook registration.

The hook should:
- Match on Bash tool usage
- Point to the post-tool-use.sh script

---

## Summary

Created `plugins/faq-check/hooks/hooks.json` with:
- PostToolUse hook registration
- Matcher configured for `tool_name: "Bash"` to filter to Bash commands only
- Command pointing to `${CLAUDE_PLUGIN_ROOT}/scripts/post-tool-use.sh`

Also removed the placeholder `.gitkeep` file from the hooks directory.
