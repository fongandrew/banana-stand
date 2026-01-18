# Refactor to PreToolUse Command Wrapping

The current approach using `PostToolUse` and `PostToolUseFailure` hooks doesn't work well because `PostToolUseFailure` does not allow injection of additional context into the agent's view of the output.

## New Approach

Switch to a `PreToolUse` hook that rewrites Bash commands to:
1. Wrap the original command to capture stdout/stderr
2. Check captured output against FAQ patterns
3. Inject matched FAQ context directly into the output stream (stderr)
4. Preserve the original command's exit code

## Changes Required

### 1. Update hooks.json

**File:** `plugins/faq-check/hooks/hooks.json`

- Remove `PostToolUse` and `PostToolUseFailure` hooks
- Add `PreToolUse` hook for Bash that modifies the `command` parameter
- The hook script should output JSON with the rewritten command

### 2. Create PreToolUse wrapper script

**File:** `plugins/faq-check/scripts/pre-tool-use.sh`

This script receives the Bash tool input and rewrites the command to wrap it with FAQ checking:

```
Original: npm install
Rewritten: /path/to/faq-wrapper.sh 'npm install'
```

Must handle:
- Proper escaping of the original command
- Opt-out via `FAQ_CHECK=0` environment variable prefix
- Output JSON in the format: `{"command": "wrapped command here"}`

### 3. Create runtime wrapper script

**File:** `plugins/faq-check/scripts/faq-wrapper.sh`

This script is what actually runs at command execution time:

1. Execute the original command, capturing stdout/stderr separately
2. Preserve and propagate original exit code
3. Output stdout to stdout, stderr to stderr (preserving streams)
4. After command completes, check output against FAQ patterns
5. If match found, append context message to stderr

Must handle:
- Complex commands with pipes, redirections, subshells
- Binary output (don't corrupt it)
- Proper exit code preservation using `PIPESTATUS` or temp files

### 4. Update FAQ file format

**File:** `.faq-check/*.yaml` (new format, replaces `.md`)

Consider switching to YAML files with embedded markdown content:

```yaml
command_match: "npm install"  # regex or substring for the command
output_match: "EACCES|permission denied"  # regex for stdout/stderr
match_on: failure  # failure | success | any
---
# Markdown content explaining the fix
This error occurs when npm doesn't have write access...
```

Or keep `.md` files but add `command_match` to frontmatter:

```yaml
---
command_match: /npm (install|ci)/i
triggers:
  - EACCES
  - /permission denied/i
match_on: failure
---
```

**Decision needed:** Keep `.md` with extended frontmatter vs switch to `.yaml`

### 5. Rename post-tool-use.sh to match-checker.sh

**File:** `plugins/faq-check/scripts/match-checker.sh`

Refactor the existing matching logic into a standalone utility that:
- Takes command string and output as arguments (or stdin)
- Checks against all FAQ files in `.faq-check/`
- Outputs the context message if matched, or nothing if no match
- Used by `faq-wrapper.sh` at runtime

### 6. Update templates/README.md

**File:** `plugins/faq-check/templates/README.md`

Update documentation to reflect:
- New frontmatter field: `command_match`
- How both command and output matching work
- Opt-out mechanism (`FAQ_CHECK=0 command`)
- New file format if switching to YAML

### 7. Update add.md command

**File:** `plugins/faq-check/commands/add.md`

Update the `/faq-check:add` skill to:
- Prompt for command pattern as well as output pattern
- Generate FAQ files in the new format
- Explain the two-pattern matching system

### 8. Delete obsolete files

- `plugins/faq-check/scripts/post-tool-use.sh` (replaced by new scripts)

### 9. Update tests

**File:** `tests/faq-check/test.sh`

Rewrite tests for the new architecture:
- Test PreToolUse command rewriting
- Test wrapper script execution
- Test command + output dual matching
- Test opt-out mechanism
- Test complex command handling
- Test exit code preservation

### 10. Update plugin README (if exists)

Document the new architecture and usage for plugin developers/maintainers.

## Technical Considerations

### Command Escaping

The wrapper needs to handle all bash syntax correctly:
- Single quotes, double quotes, escaped characters
- Pipes, redirections, command substitution
- Heredocs, process substitution
- Multi-line commands

### Exit Code Preservation

```bash
# Pattern for preserving exit code
original_command
exit_code=$?
# ... do FAQ checking ...
exit $exit_code
```

### Opt-Out Detection

Check for `FAQ_CHECK=0` at the start of the command:
```bash
if [[ "$command" =~ ^FAQ_CHECK=0[[:space:]] ]]; then
    # Strip the prefix and run without wrapping
fi
```

### Output Injection

Append to stderr so it doesn't corrupt stdout parsing:
```bash
echo "[FAQ] See .faq-check/port-conflicts.md for guidance" >&2
```

## Open Questions

1. Should we keep `.md` files with extended frontmatter or switch to `.yaml`?
2. Should the wrapper script be copied to a temp location or referenced from plugin dir?
3. How should we handle commands that read from stdin?
4. Should there be a way to disable FAQ checking globally (env var in shell profile)?
