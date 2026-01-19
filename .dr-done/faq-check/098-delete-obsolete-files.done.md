# Delete Obsolete Files

After the new scripts are in place and working:

1. Delete `plugins/faq-check/scripts/post-tool-use.sh` (replaced by new pre-tool-use architecture)

Only do this after:
- 091-update-hooks-json.md is complete
- 092-create-pre-tool-use-script.md is complete
- 093-create-faq-wrapper-script.md is complete
- 094-create-match-checker-script.md is complete

Reference the parent task `090-refactor.md` for full context.

---

## Completion Summary

Deleted `plugins/faq-check/scripts/post-tool-use.sh` as it has been replaced by the new pre-tool-use architecture consisting of:
- `pre-tool-use.sh` - Entry point hook
- `faq-wrapper.sh` - Main orchestration logic
- `match-checker.sh` - Pattern matching and permission request handling
