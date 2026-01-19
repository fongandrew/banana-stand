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

---

## Summary

Rewrote `tests/faq-check/test.sh` with comprehensive unit tests for the new PreToolUse architecture:

**Tests Added (25 unit tests):**
- **pre-tool-use.sh tests (4):** Basic wrapping, opt-out mechanism, empty command, single quotes handling
- **faq-wrapper.sh tests (10):** Exit code preservation (success/failure), stdout/stderr passthrough, pipes, redirections, subshells, FAQ match on failure/success, no-match cases
- **match-checker.sh tests (11):** Literal triggers, regex triggers, command_match filtering, match_on=failure/success/any behavior, exit code handling

**Bug Fixed:**
- Fixed binary detection in `faq-wrapper.sh` - the `grep -q $'\x00'` approach didn't work reliably on macOS (null byte was treated as empty string matching everything). Replaced with a more robust `tr -d '\0' | cmp` approach.

**Integration tests** (Phase 3) require Claude CLI and are skipped if unavailable.
