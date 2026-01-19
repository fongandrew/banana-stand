# Update Templates README

Update `plugins/faq-check/templates/README.md` to reflect the new architecture:

1. Document the new frontmatter field: `command_match`
2. Explain how both command and output matching work together
3. Document the `match_on` field (failure/success/any)
4. Explain the opt-out mechanism (`FAQ_CHECK=0 command`)
5. Update any examples to show the new format

Reference the parent task `090-refactor.md` for full context.

---

## Summary

Updated `plugins/faq-check/templates/README.md` with comprehensive documentation:

- Added documentation for `command_match` frontmatter field with literal and regex pattern examples
- Added "How Matching Works" section explaining the two-stage matching approach (command + output)
- Clarified that both `command_match` AND triggers must match when `command_match` is specified
- Added "Opting Out of FAQ Checking" section documenting the `FAQ_CHECK=0` mechanism
- Added three example FAQ files demonstrating different use cases:
  - Command + Output Matching (npm permission errors)
  - Output-Only Matching (port conflicts)
  - Success Matching (post-deployment steps)
- Added "How It Works Internally" section explaining the PreToolUse hook architecture
- Reorganized tips section to mention `command_match` for scoping FAQs
