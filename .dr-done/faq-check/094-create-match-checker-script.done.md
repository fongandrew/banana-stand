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

---

## Completion Summary

Created `plugins/faq-check/scripts/match-checker.sh` with the following features:

- Reads input via environment variables: `FAQ_COMMAND`, `FAQ_OUTPUT`, `FAQ_EXIT_CODE`
- Walks up from current directory to find `.faq-check/` directory
- Parses FAQ markdown files with YAML frontmatter
- Supports `match_on` field: failure/success/any (defaults to failure)
- Supports `command_match` frontmatter field for dual command+output matching
- Supports output triggers (both literal and regex patterns)
- Returns exit code 0 with FAQ context message on match, exit code 1 on no match
- Single match shows teaser (first paragraph), multiple matches list filenames

Tested with:
- Failure case with exact match trigger
- Success case with exact match trigger
- No match case (returns exit code 1)
- Regex pattern matching (case-insensitive)
