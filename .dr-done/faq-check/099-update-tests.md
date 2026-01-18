# Update Tests for New Architecture

Rewrite `tests/faq-check/test.sh` for the new PreToolUse architecture:

1. Test PreToolUse command rewriting (pre-tool-use.sh)
2. Test wrapper script execution (faq-wrapper.sh)
3. Test command + output dual matching (match-checker.sh)
4. Test opt-out mechanism (FAQ_CHECK=0 prefix)
5. Test complex command handling (pipes, quotes, redirections)
6. Test exit code preservation
7. Test match_on behavior (failure/success/any)

Reference the parent task `090-refactor.md` for full context.
