# Update FAQ File Format

Update the FAQ file format (`.faq-check/*.md`) to support command matching:

1. Keep the `.md` format with extended YAML frontmatter (don't switch to `.yaml`)
2. Add new frontmatter field: `command_match` - regex or substring to match against the command
3. Keep existing `triggers` field for output matching
4. Add `match_on` field with values: `failure` (default), `success`, or `any`

Example new format:
```yaml
---
command_match: /npm (install|ci)/i
triggers:
  - EACCES
  - /permission denied/i
match_on: failure
---

# FAQ Content Here
This error occurs when npm doesn't have write access...
```

Update the example FAQ files in `tests/faq-check/.faq-check/` to use the new format.

Reference the parent task `090-refactor.md` for full context.
