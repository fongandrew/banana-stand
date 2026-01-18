# Create Match Checker Utility Script

Refactor the existing matching logic from `post-tool-use.sh` into a standalone utility:

Create `plugins/faq-check/scripts/match-checker.sh` that:

1. Takes command string and output as arguments (or via stdin/env vars)
2. Takes the exit code as an argument to support match_on: failure/success/any
3. Finds and reads all FAQ files in `.faq-check/` directory
4. Checks both command_match and output triggers against the input
5. Respects the `match_on` frontmatter field (failure/success/any)
6. Outputs the context message (FAQ content) if matched, or nothing if no match
7. Returns exit code 0 if match found, 1 if no match

This script will be called by `faq-wrapper.sh` at runtime.

Reference the parent task `090-refactor.md` and existing `post-tool-use.sh` for context.
