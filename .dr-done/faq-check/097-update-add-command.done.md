# Update Add Command Skill

Update `plugins/faq-check/commands/add.md` to:

1. Prompt for command pattern as well as output pattern
2. Generate FAQ files in the new format (with command_match frontmatter)
3. Explain the two-pattern matching system to users
4. Include examples of command_match patterns

Reference the parent task `090-refactor.md` for full context.

---

## Summary

Updated the `/faq-check:add` command skill with the following changes:

1. **Added Step 1** - Explains the two-pattern matching system (command pattern + output triggers)
2. **Added Step 2** - Prompts for optional command pattern with examples:
   - Literal strings: `npm install`, `docker build`
   - Regex patterns: `/npm (install|ci)/i`, `/pip install/i`
3. **Renumbered subsequent steps** (Steps 3-7)
4. **Updated file format examples** - Shows both with and without `command_match` frontmatter
5. **Updated confirmation message** - Explains conditional behavior based on whether command_match was specified
