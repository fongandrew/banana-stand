# Update Templates README

Update `plugins/faq-check/templates/README.md` to reflect the new architecture:

1. Document the new frontmatter field: `command_match`
2. Explain how both command and output matching work together
3. Document the `match_on` field (failure/success/any)
4. Explain the opt-out mechanism (`FAQ_CHECK=0 command`)
5. Update any examples to show the new format

Reference the parent task `090-refactor.md` for full context.
