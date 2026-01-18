# Create PreToolUse Wrapper Script

Create `plugins/faq-check/scripts/pre-tool-use.sh` that:

1. Receives the Bash tool input (command parameter)
2. Checks for opt-out via `FAQ_CHECK=0` prefix - if present, strip prefix and pass through unchanged
3. Rewrites the command to wrap it with the FAQ wrapper:
   - Original: `npm install`
   - Rewritten: `/path/to/faq-wrapper.sh 'npm install'`
4. Handles proper escaping of the original command (quotes, special chars)
5. Outputs JSON in format: `{"command": "wrapped command here"}`

The script path should use `$PLUGIN_DIR` or similar mechanism to locate the faq-wrapper.sh script.

Reference the parent task `090-refactor.md` for full context.

---

## Completion Summary

Created `plugins/faq-check/scripts/pre-tool-use.sh` that:

- Reads Bash tool input JSON from stdin
- Parses the `command` parameter using `jq`
- Detects `FAQ_CHECK=0` prefix and strips it for opt-out
- Wraps non-opted-out commands with the FAQ wrapper script path
- Properly escapes single quotes using the `'\''` technique
- Uses `$PLUGIN_DIR` derived from script location to locate faq-wrapper.sh
- Outputs JSON with rewritten command using `jq -n`

Tested with: basic commands, opt-out prefix, single quotes, double quotes, pipes, variables, and missing command parameter.
