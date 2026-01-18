# Create Runtime FAQ Wrapper Script

Create `plugins/faq-check/scripts/faq-wrapper.sh` that runs at command execution time:

1. Accept the original command as an argument
2. Execute the original command, capturing stdout/stderr separately
3. Output stdout to stdout, stderr to stderr (preserving streams)
4. Preserve and propagate the original exit code (use temp file or PIPESTATUS)
5. After command completes, check output against FAQ patterns using match-checker.sh
6. If a match is found, append context message to stderr

Must handle:
- Complex commands with pipes, redirections, subshells
- Binary output (don't corrupt it)
- Proper exit code preservation

Example flow:
```
faq-wrapper.sh 'npm install'
-> runs: npm install
-> captures output
-> checks FAQs
-> if match: echo "[FAQ] See .faq-check/xyz.md for guidance" >&2
-> exits with npm's exit code
```

Reference the parent task `090-refactor.md` for full context.

---

## Completion Summary

Created `plugins/faq-check/scripts/faq-wrapper.sh` with the following features:

1. **Command execution**: Uses `eval` in a subshell to properly handle complex commands with pipes, redirections, and subshells
2. **Output capture**: Uses temp files to capture stdout/stderr separately
3. **Stream preservation**: Outputs are passed through using `cat` to preserve exact bytes including trailing newlines and binary content
4. **Exit code preservation**: Captures exit code immediately after command execution and propagates it
5. **Binary detection**: Checks for null bytes to identify binary output and marks it as `[binary output]` for FAQ matching
6. **Match checker integration**: Calls `match-checker.sh` (to be created in task 094) via environment variables for clean data passing
7. **FAQ output**: Appends any matched FAQ context to stderr

The script is designed to work with `pre-tool-use.sh` which wraps commands before execution. Tested with:
- Simple echo commands
- Commands with stderr output
- Exit code preservation (non-zero exits)
- Piped commands
- Commands with special characters and variable expansion
- Multi-line output
